Client
======
The Client brings everything together and runs the logic of a participant.
It realises the participants actions in terms of channel proposals, updates or closing.
To offer these functionalities, the Client includes a Perun Client, the Asset Holder, the Asset Holder Address and a Context Timeout.
This is a very simple Client, which is sufficient for our basic Payment Channel example.
In more complex use cases, e.g. for App Channels, this Client is extended.

.. code-block:: go

    type Client struct {
        role            Role
        PerunClient     *PerunClient
        AssetHolderAddr common.Address
        AssetHolder     *assetholdereth.AssetHolderETH
        ContextTimeout  time.Duration
        Channel         *client.Channel
    }

Open, Close & Update Channel
--------------------
We define three types of interaction from the Client to the Channel.

For opening a channel we use `OpenChannel()` that takes the opponents address as an argument.
In our example we say that Alice and Bob both start out with a balance of 10 ETH.
According to this we set the initial allocation of the channel with `channel.Allocation{}`.
This defines our asset type and how much of this asset will be allocated to the participants at the start (therefore, how much each participant needs to deposit to use the channel), which sum implies the amount of ETH that must be available in the channel at any point of time.
Further we define the `peers`, which are the wire addresses (transport layer) of the channel participants.

Next we generate the channel proposal that includes the `challengeDuration`, a timeframe in which the proposal can be accepted (in our case 10 seconds),
the clients address, the channel allocation `initBals` and our `peers`.
Then we send the proposal with `c.PerunClient.StateChClient.ProposeChannel(ctx, proposal)`.
`ctx` is used to abort if the proposal is not accepted in time.
Finally a watcher, that listens for events on the potential new channel, is started via `HandleNewChannel()` which we will take a look at later in this section.

.. code-block:: go

    func (c *Client) OpenChannel(opponent wallet.Address) error {
        fmt.Printf("%s: Opening channel from %s to %s\n", c.RoleAsString(), c.RoleAsString(), c.OpponentRoleAsString())

        initBal := eth.EthToWei(big.NewFloat(10))

        initBals := &channel.Allocation{
            Assets:   []channel.Asset{ethwallet.AsWalletAddr(c.AssetHolderAddr)},
            Balances: [][]*big.Int{{initBal, initBal}},
        }

        peers := []wire.Address{c.PerunClient.Account.Address(), opponent}

        // Prepare the proposal by defining the channel parameters.
        proposal, err := client.NewLedgerChannelProposal(10, c.PerunAddress(), initBals, peers)
        if err != nil {
            return fmt.Errorf("creating channel proposal: %w", err)
        }
        ctx, cancel := c.defaultContextWithTimeout()
        defer cancel()

        // Send the proposal.
        ch, err := c.PerunClient.StateChClient.ProposeChannel(ctx, proposal)
        c.Channel = ch

        // Start the on-chain watcher to listen for events
        c.HandleNewChannel(ch) // TODO: 2/2 Check with MG why this is needed here (and not needed in App Channel example)

        if err != nil {
            return fmt.Errorf("proposing channel: %w", err)
        }
        fmt.Printf("\n 🎉 Opened channel with id 0x%x \n\n", ch.ID())
        return nil
    }

For proposing a channel update we use `UpdateChannel()`.
Our basic logic here is, that updating will simply send 5 ETH from the calling client to the opponent.
This function could be modified of course e.g. for sending or requesting a parameterized amount.
The amount could also be very small to realize micro-transactions.

We use `channel.UpdateBy()` for conveniently proposing an update to the channels `state`.
It is important that any update maintains the overall sum of funds inside the channel. Otherwise the update cannot happen.
Note that we access the balances via `state.Balances[0][role]`.
0 indicates that the first asset (in our case the only asset: ETH) should be modified.
If we would have a multi-asset channel we could use other indices here. `role` is used for specifying the participant.

Before we send the update we finalize the channel with setting `state.IsFinal` to `True`.
This limits our example to only one update call because after a channel is finalized it cannot be updated anymore.
In practice a client would only finalize a channel if it intends to close/exit the channel.

.. code-block:: go

    func (c *Client) UpdateChannel() error {
        fmt.Printf("%s: Update channel by sending 5 ETH to %s \n", c.RoleAsString(), c.OpponentRoleAsString())

        ctx, cancel := c.defaultContextWithTimeout()
        defer cancel()
        // Use UpdateBy to conveniently update the channels state.
        return c.Channel.UpdateBy(ctx, func(state *channel.State) error {
            // Shift 5 ETH from caller to opponent.
            amount := eth.EthToWei(big.NewFloat(5))
            state.Balances[0][1-c.role].Sub(state.Balances[0][1-c.role], amount)
            state.Balances[0][c.role].Add(state.Balances[0][c.role], amount)
            // Finalize the channel, this will be important in the next step.
            state.IsFinal = true
            return nil
        })
    }

Finally, for closing a channel we use `CloseChannel()`.
Closing a channel can be done in two ways, either cooperative or non-cooperative.
This example focuses on the cooperative way, therefore, we expect the channel to be finalized (described above).
As you would expect from closing an off-chain channel, the on-chain balances will be updated accordingly.

The first step is to register the channel via `channel.Register()`.
Registering a channel means pushing its latest state onto the `Adjudicator`.
A registered channel state is openly visible on the blockchain.
This should only be done when a channel should be closed or disputed.
Note that registering non-finalized channels will raise a dispute.

Next the channel is settled via `channel.Settle()`.
Internally the settlement consists of two steps: `conclude` and `withdraw`.
The `conclude` step waits for any on-chain disputes to be resolved and then calls the Adjudicator to close the channel.
After this is done the participants can withdraw (once!) their funds from the `AssetHolder`.
The balance that can be withdrawn is the same as the final balance of the channel.

Finally `channel.Close()` is called which closes the channel and all associated subscriptions for the client locally.
This step has nothing to do with any on-chain actions. On-chain the channel's lifetime ends after the settlement.

.. code-block:: go

    func (c *Client) CloseChannel() error {
        fmt.Printf("%s: Close Channel \n", c.RoleAsString())

        ctx, cancel := c.defaultContextWithTimeout()
        defer cancel()

        if err := c.Channel.Register(ctx); err != nil {
            return fmt.Errorf("registering channel: %w", err)
        }
        if err := c.Channel.Settle(ctx, false); err != nil {
            return fmt.Errorf("settling channel: %w", err)
        }
        // .Close() closes the channel object and has nothing to do with the
        // go-perun channel protocol.
        if err := c.Channel.Close(); err != nil {
            return fmt.Errorf("closing channel object: %w", err)
        }
        return nil
    }


Handlers / Callbacks
--------
As mentioned in the Perun Client section go-perun uses callbacks to forward interactions from the channel to the user.
This is done by the State Channel Client coming with the Perun Client.

