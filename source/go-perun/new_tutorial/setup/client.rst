Client
======
The Client brings everything together and runs the logic of a participant.
It realizes the participant's channel proposals, updates, or closing actions.
The Client includes a Perun Client, the Asset Holder, the Asset Holder Address, and a Context Timeout to offer these functionalities.
In the following, we present a straightforward Client, sufficient for our basic Payment Channel example.
This Client is extended in more complex use cases, e.g., for App Channels.

.. code-block:: go

    type Client struct {
        role            Role
        PerunClient     *PerunClient
        AssetHolderAddr common.Address
        AssetHolder     *assetholdereth.AssetHolderETH
        ContextTimeout  time.Duration
        Channel         *client.Channel
    }

Client to Channel
--------------------
We define three types of interaction from the Client to the Channel.

Opening a Channel
~~~~~~~~~~
We use `OpenChannel()` for opening a Channel, which takes the opponents' address as an argument.
In our example, we say that Alice and Bob both start with a balance of 10 ETH.
According to this, we set the initial allocation of the Channel with `channel.Allocation{}`.
This defines our asset type and how much of this asset will be allocated to the participants at the start (therefore, how much each participant needs to deposit to use the Channel), which sum implies the amount of ETH that must be available in the Channel at any point of time.
Further, we define the `peers`, which are the channel participants' wire addresses (transport layer).

Next, we generate the Channel proposal that includes the `challengeDuration`, a timeframe in which the proposal can be accepted (in our case, 10 seconds),
the Client's address, the channel allocation `initBals`, and our `peers`.

Then we send the proposal with `.ProposeChannel(ctx, proposal)`.
`ctx` is used to abort if the proposal is not accepted in time.
Ultimately, a watcher that listens for events on the potential new Channel is started via `HandleNewChannel()`, which we will look at later in this section.

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

        if err != nil {
            return fmt.Errorf("proposing channel: %w", err)
        }

        // Start the on-chain watcher to listen for events
        c.HandleNewChannel(ch) // TODO: 2/2 Check with MG why this is needed here (and not needed in App Channel example)

        fmt.Printf("\n 🎉 Opened channel with id 0x%x \n\n", ch.ID())
        return nil
    }

Updating a Channel
~~~~~~~~~~
For proposing a channel update we use `UpdateChannel()`.
Our basic logic is that updating will send 5 ETH from the calling Client to the opponent.
Of course, this function could be modified, e.g., for sending or requesting a parameterized amount.
The amount could also be very small to realize micro-transactions.

We use `channel.UpdateBy()` for conveniently proposing an update to the Channel's `state`.
Any update must maintain the overall sum of funds inside the Channel. Otherwise, the update cannot happen.
Note that we access the balances via `state.Balances[0][role]`.
0 indicates that the first asset (in our case, the only asset: ETH) should be modified.
If we had a multi-asset Channel, we could use other indices here. `role` specifies the participant.

Before sending the update, we finalize the Channel by setting `state.IsFinal` to `True`.
This limits our example to only one update call because after a Channel is finalized, it cannot be updated anymore.
In practice, a Client would only finalize a channel if it intends to close/exit the Channel.

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

Closing a Channel
~~~~~~~~~~
Finally, for closing a Channel, we use `CloseChannel()`.
Closing a channel can be done in two ways, either cooperative or non-cooperative.
This example focuses on the cooperative way. Therefore, we expect the Channel to be finalized (described above).
As you would expect from closing an off-chain channel, the on-chain balances will be updated accordingly.

The first step is to register the Channel via `channel.Register()`.
Registering a channel means pushing its latest state onto the `Adjudicator`.
A registered channel state is openly visible on the blockchain.
This should only be done when a channel should be closed or disputed.
Note that registering non-finalized channels will raise a dispute.

Next the Channel is settled via `channel.Settle()`.
Internally the settlement consists of two steps: `conclude` and `withdraw`.
The `conclude` step waits for any on-chain disputes to be resolved and then calls the Adjudicator to close the Channel.
After this is done, the participants can withdraw (once!) their funds from the `AssetHolder`.
The balance that can be withdrawn is the same as the final balance of the Channel.

Ultimately `channel.Close()` is called, which closes the Channel and all associated subscriptions for the Client locally.
This step has nothing to do with any on-chain actions. On-chain the Channel's lifetime ends after the settlement.

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


Channel to Client
--------
As mentioned in the Perun Client section, go-perun uses callbacks to forward interactions from the Channel to the user.
This is managed via the `handler` routine of the State Channel Client, which is included in the Perun Client.

Handling Channel Proposals
~~~~~~~~~~
`HandleProposal()` is triggered on incoming channel proposals.
In our case, we expect a proposed channel to be a basic ledger channel. Therefore, we check if the proposal is of type `LedgerChannelProposal` before continuing.
You can add additional check logic here, but in our simple use case, besides checking the proposal type, we always accept.

To accept the Channel, we follow two steps:
First, we create the accept message, including the Client's address and a random nonce.
This is done by simply calling `proposal.Accept()` on the proposal object.
Then we send the accept message via the responder `responder.Accept()`.
If this is successful, we call `HandleNewChannel()`.

.. code-block:: go

    func (c *Client) HandleProposal(proposal client.ChannelProposal, responder *client.ProposalResponder) {
        // Check that we got a ledger channel proposal.
        _proposal, ok := proposal.(*client.LedgerChannelProposal)
        if !ok {
            fmt.Printf("%s: Received a proposal that was not for a ledger channel.", c.RoleAsString())
            return
        }
        fmt.Printf("%s: Received channel proposal\n", c.RoleAsString())

        ctx, cancel := c.defaultContextWithTimeout()
        defer cancel()

        // Create a channel accept message and send it.
        accept := _proposal.Accept(c.PerunAddress(), client.WithRandomNonce())
        ch, err := responder.Accept(ctx, accept)

        if err != nil {
            fmt.Printf("%s: Accepting channel: %w\n", c.RoleAsString(), err)
        } else {
            fmt.Printf("%s: Accepted channel with id 0x%x\n", c.RoleAsString(), ch.ID())
        }

        c.HandleNewChannel(ch) // TODO: 1/2 Check with MG why this is needed here (and not needed in App Channel example)
    }

Handling a new Channel
~~~~~~~~~~
`HandleNewChannel()` should always be called by the Client once it is aware of a new channel. (like you have seen in `OpenChannel()` or `HandleProposal()`)
Its purpose is to start a watcher that watches the Adjudicator for on-chain channel events and notifies the handler accordingly.
Starting the watcher is strongly advised. Otherwise, go-perun will not react to (possibly malicious) on-chain behavior, and users risk losing funds.
All that needs to be done here is to start the on-chain watcher via `Channel.Watch()`.

.. code-block:: go

    func (c *Client) HandleNewChannel(ch *client.Channel) {
        fmt.Printf("%s: HandleNewChannel with id 0x%x\n", c.RoleAsString(), ch.ID())
        c.Channel = ch
        // Start the on-chain watcher.
        go func() {
            err := ch.Watch(c)
            if err != nil {
                fmt.Printf("%s: Watcher returned with: %s", c.RoleAsString(), err)
            }
        }()
    }


Handling Adjudicator Events
~~~~~~~~~~
If the previously described on-chain watcher notices a state change in the Adjudicator `HandleAdjudicatorEvent()` is triggered.
In our case, we do not expect any malicious behavior. Therefore, an adjudicator event signals the closing of the Channel for us.
We check if the propagated `channel.AdjudicatorEvent` is indeed of type `channel.ConcludedEvent` and close the Channel
via `Client.CloseChannel()` if this is is the case.

Notice that we check for Alice's role here.
We do this because, in our example, Bob is explicitly closing the Channel.
Therefore, only Alice needs to respond to this adjudicator event.

.. code-block:: go

    func (c *Client) HandleAdjudicatorEvent(e channel.AdjudicatorEvent) {
        fmt.Printf("%s: HandleAdjudicatorEvent\n", c.RoleAsString())
        if _, ok := e.(*channel.ConcludedEvent); ok && c.role == RoleAlice {
            err := c.CloseChannel()
            if err != nil {
                log.Error(err)
            }
        }
    }


Handling Channel Updates
~~~~~~~~~~
For deciding how to handle incoming channel updates (off-chain!), we define `HandleUpdate()`.
You can define complex logic here that decides if an update will be accepted or rejected.
Therefore, `channel.State` and `client.ChannelUpdate` are given as arguments.
The `State` is the current channel state, and the `ChannelUpdate` includes the proposed new state.
In this example, we will simply accept every update and only make use of the `client.UpdateResponder` by calling `.Accept()`

.. code-block:: go

    func (c *Client) HandleUpdate(state *channel.State, update client.ChannelUpdate, responder *client.UpdateResponder) {
        fmt.Printf("%s: HandleUpdate\n", c.RoleAsString())
        ctx, cancel := c.defaultContextWithTimeout()
        defer cancel()

        // We will accept every update
        if err := responder.Accept(ctx); err != nil {
            fmt.Printf("%s: Could not accept update: %v\n", c.RoleAsString(), err)
        }
    }


Start the Client
--------
Let us combine our earlier steps to initialize the `Client` itself.

    #. We create the Perun Client by calling `setupPerunClient` with the `PerunClientConfig`.
    #. Then we load the (already existing!) asset holder with the address given in the config via `assetholdereth.NewAssetHolderETH`.
    #. Next, we create the actual Client from all its pieces. Notice that there is no channel existing yet. Therefore, the respective field is `nil`.
    #. The handler routine is started, which will trigger callbacks concerning channel proposals and update requests. You might wonder why for both arguments (`ProposalHandler`, `UpdateHandler`), the Client itself is given (`.Handle(c, c)`). This is because we implement both interfaces in our Client by providing `HandleProposal()` and `HandleUpdate()`. If you want, you could separate this functionality, of course.
    #. Ultimately the listener routine is started that listens for incoming connections and automatically adds them to the bus.

We return the generated `Client` to conclude this section.

.. code-block:: go

    type ClientConfig struct {
        PerunClientConfig
        ContextTimeout time.Duration
    }

    func StartClient(cfg ClientConfig) (*Client, error) {
        perunClient, err := setupPerunClient(cfg.PerunClientConfig)
        if err != nil {
            return nil, errors.WithMessage(err, "creating perun client")
        }

        ah, err := assetholdereth.NewAssetHolderETH(cfg.AssetHolderAddr, perunClient.ContractBackend)
        if err != nil {
            return nil, errors.WithMessage(err, "loading asset holder")
        }

        c := &Client{
            cfg.Role,
            perunClient,
            cfg.AssetHolderAddr,
            ah,
            cfg.ContextTimeout,
            nil,
        }

        go c.PerunClient.StateChClient.Handle(c, c)
        go c.PerunClient.Bus.Listen(c.PerunClient.Listener)

        return c, nil
    }
