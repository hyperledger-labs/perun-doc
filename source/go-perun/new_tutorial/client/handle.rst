Channel to Client
-----------------
As mentioned in the Perun Client section, go-perun uses callbacks to forward interactions from the Channel to the user.
This is managed via the `handler` routine of the State Channel Client, which is included in the Perun Client.
The following code is located in the client package's handle.go.

Handling Channel Proposals
~~~~~~~~~~~~~~~~~~~~~~~~~~
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
~~~~~~~~~~~~~~~~~~~~~~
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
~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
~~~~~~~~~~~~~~~~~~~~~~~~
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
----------------
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