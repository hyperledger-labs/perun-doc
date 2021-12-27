Handler
=======

Our app channel client's handler provides callbacks for handling incoming app channel proposals and updates.

Handling Channel Proposals
~~~~~~~~~~~~~~~~~~~~~~~~~~
This part is again very similar to the payment channel example with the difference that we now expect a specific app channel that receives equal funding from both sides.
For uncertainties over the other steps, look at :ref:`the previous explanation <client-handle-proposals>`.

To ensure that the proposal includes the correct app, we check if the proposal's app address (which is the address of the app's smart contract) equals the one the client is expecting.
By calling `lcp.FundingAgreement` we fetch the expected funding of the proposal and validate that the client is only required to fund what the proposing party agreed to fund, which ensures that both have the same wager.

.. code-block:: go
    :emphasize-lines: 10-12, 30,31

    // HandleProposal is the callback for incoming channel proposals.
    func (c *AppClient) HandleProposal(p client.ChannelProposal, r *client.ProposalResponder) {
        lcp, err := func() (*client.LedgerChannelProposal, error) {
            // Ensure that we got a ledger channel proposal.
            lcp, ok := p.(*client.LedgerChannelProposal)
            if !ok {
                return nil, fmt.Errorf("Invalid proposal type: %T\n", p)
            }

            // Ensure the ledger channel proposal includes the expected app.
            if !lcp.App.Def().Equals(c.app.Def()) {
                return nil, fmt.Errorf("Invalid app type ")
            }

            // Check that we have the correct number of participants.
            if lcp.NumPeers() != 2 { //TODO:go-perun rename NumPeers to NumParts, Peers to Participants anywhere where all parties are referred to
                return nil, fmt.Errorf("Invalid number of participants: %d", lcp.NumPeers())
            }

            // Check that the channel has the expected assets.
            err := channel.AssetsAssertEqual(lcp.InitBals.Assets, []channel.Asset{c.currency})
            if err != nil {
                return nil, fmt.Errorf("Invalid assets: %v\n", err)
            }

            // Check that the channel has the expected assets and funding balances.
            const assetIdx, peerIdx = 0, 1
            if err := channel.AssetsAssertEqual(lcp.InitBals.Assets, []channel.Asset{c.currency}); err != nil {
                return nil, fmt.Errorf("Invalid assets: %v\n", err)
            } else if lcp.FundingAgreement[assetIdx][peerIdx].Cmp(c.stake) != 0 {
                return nil, fmt.Errorf("Invalid funding balance")
            }
            return lcp, nil
        }()
        if err != nil {
            r.Reject(context.TODO(), err.Error()) //nolint:errcheck // It's OK if rejection fails.
        }

As in the payment channel example, we create the accept message, send it, and start the on-chain watcher.

.. code-block:: go

        // Create a channel accept message and send it.
        accept := lcp.Accept(
            c.account,                // The account we use in the channel.
            client.WithRandomNonce(), // Our share of the channel nonce.
        )
        ch, err := r.Accept(context.TODO(), accept)
        if err != nil {
            fmt.Printf("Error accepting channel proposal: %v\n", err)
            return
        }

        // Start the on-chain event watcher. It automatically handles disputes.
        c.startWatching(ch)

        c.channels <- newAppChannel(ch)
    }

Handling Update
~~~~~~~~~~~~~~~
We don't need to do a lot here in the app channel case.
Basically, we can accept every update we receive because the perun app-channel automatically checks that the transition is valid.
What a "valid transition" is will be implemented at :ref:`a later stage in this tutorial <app-validate-transition>`.
We do not make any requirements to balance changes here because our client must accept if it loses the game.

.. code-block:: go

    // HandleUpdate is the callback for incoming channel updates.
    func (c *AppClient) HandleUpdate(cur *channel.State, next client.ChannelUpdate, r *client.UpdateResponder) {
        // Perun automatically checks that the transition is valid.
        // We always accept.
        err := r.Accept(context.TODO())
        if err != nil {
            panic(err)
        }
    }

.. toctree::
   :hidden:
