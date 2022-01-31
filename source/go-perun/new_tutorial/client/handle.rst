.. _client-handle:

Handler
-------
As mentioned in the Client section, go-perun uses callbacks to handle incoming channel proposals and channel update requests.
The callbacks are managed via the `handler`, that comes with the Perun Client.
The following code is located in `client/handle.go`.

Handling Channel Proposals
~~~~~~~~~~~~~~~~~~~~~~~~~~
`HandleProposal()` is triggered on incoming Channel proposals.
Before any Channel is accepted, it is essential to validate its "terms and conditions".

In our case, the Client expects the following properties to be met:

#. The proposed payment-channel must be a standard `LedgerChannel`, therefore the proposal is expected to be of type `LedgerChannelProposal`.
#. Exactly two peers should participate in the payment-channel. This is validated by `.NumPeers()`.
#. The type of asset the Channel takes must be equivalent to the type the Client expects to use for payment.
#. We say the Client does not want to fund anything. Therefore, the Client expects its initial balance to be zero. Of course, some upper limit would be a sensible value here in real-world scenarios.

You can add any additional checks to the logic, but in our simple use case, besides checking the above, we always accept.

.. code-block:: go

    // HandleProposal is the callback for incoming channel proposals.
    func (c *PaymentClient) HandleProposal(p client.ChannelProposal, r *client.ProposalResponder) {
        lcp, err := func() (*client.LedgerChannelProposal, error) {
            // Ensure that we got a ledger channel proposal.
            lcp, ok := p.(*client.LedgerChannelProposal)
            if !ok {
                return nil, fmt.Errorf("Invalid proposal type: %T\n", p)
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

            // Check that we do not need to fund anything.
            zeroBal := big.NewInt(0)
            for _, bals := range lcp.FundingAgreement {
                bal := bals[receiverIdx]
                if bal.Cmp(zeroBal) != 0 {
                    return nil, fmt.Errorf("Invalid funding balance: %v", bal)
                }
            }
            return lcp, nil
        }()
        if err != nil {
            r.Reject(context.TODO(), err.Error()) //nolint:errcheck // It's OK if rejection fails.
        }

To accept the Channel, we follow two steps:
First, we create the accept message, including the Client's address and a random nonce.
This is done by simply calling `proposal.Accept()` on the proposal object.
Then we send the accept message via the responder `responder.Accept()`.

If this is successful, we call `startWatching()` to allow the Client to react to disputes on the accepted Channel automatically.
Finally, we add the `PaymentChannel` to the Clients channel registry.

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

        // Store channel.
        c.channels <- newPaymentChannel(ch, c.currency)
    }

Handling Channel Updates
~~~~~~~~~~~~~~~~~~~~~~~~
For deciding how to handle incoming channel updates (off-chain!), we define `HandleUpdate()`.
You can define logic here that decides under which conditions an update is accepted or rejected.
In order to evaluate this, the current channel state `cur` given as `channel.State` and the proposed new state `next` given as `client.ChannelUpdate` come as arguments.
For accepting or rejecting the proposed update `client.UpdateResponder` `r` is given.

We will accept every update that increases our balance in our example. Therefore, we perform the following steps:

#. Check if the type of asset is still the asset from the state before by calling `channel.AssetsAssertEqual()`.
#. Fetch our balance from the current state `cur` and our balance in the next state `next` via  `Allocation.Balance()`.
#. Compare these balances with `balance.Cmp()`, which subtracts the values. If the resulting value is positive, our balance increases.

Again, you are free to add any additional checks to the logic here to change the Clients' behavior when accepting Channel updates.

.. code-block:: go

        // HandleUpdate is the callback for incoming channel updates.
    func (c *PaymentClient) HandleUpdate(cur *channel.State, next client.ChannelUpdate, r *client.UpdateResponder) {
        // We accept every update that increases our balance.
        err := func() error {
            err := channel.AssetsAssertEqual(cur.Assets, next.State.Assets) //TODO:go-perun move assets to parameters to disallow changing the assets until there is a use case for that?
            if err != nil {
                return fmt.Errorf("Invalid assets: %v", err)
            }

            //TODO:go-perun bug, machine.go: `validTransition` checks whether balances per asset index are preserved, but does not check whether assets are the same.
            curBal := cur.Allocation.Balance(receiverIdx, c.currency)
            nextBal := next.State.Allocation.Balance(receiverIdx, c.currency)
            if nextBal.Cmp(curBal) < 0 {
                return fmt.Errorf("Invalid balance: %v", nextBal)
            }
            return nil
        }()
        if err != nil {
            r.Reject(context.TODO(), err.Error()) //nolint:errcheck // It's OK if rejection fails.
        }

If all checks above pass, we accept the update by calling `.Accept()` on the `client.UpdateResponder`.

.. code-block:: go

        // Send the acceptance message.
        err = r.Accept(context.TODO())
        if err != nil {
            panic(err)
        }
    }


.. toctree::
   :hidden:
