.. _client-handle:

Handler
-------
As mentioned in the :ref:`client description<client-handler-mention>`, go-perun uses callbacks to handle incoming channel proposals and channel update requests.
The callbacks are managed via the `handler`, that comes with the Perun Client.
The following code is located in `client/handle.go`.

Handling Channel Proposals
~~~~~~~~~~~~~~~~~~~~~~~~~~
`HandleProposal()` is triggered on incoming channel proposals.
Before any channel is accepted, it is essential to validate its "terms and conditions".

In our case, the client expects the following properties to be met:

#. The proposed payment channel must be a standard `LedgerChannel`, therefore the proposal is expected to be of type `LedgerChannelProposalMsg`.
#. Exactly two peers should participate in the payment channel. This is validated by `.NumPeers()`.
#. The type of asset the channel takes must be equivalent to the type the client expects to use for payment.
#. We say the client does not want to fund anything. Therefore, the client expects its initial balance to be zero. Of course, some upper limit would be a sensible value here in real-world scenarios.

You can add any additional checks to the logic, but in our simple use case, besides checking the above, we always accept.

.. literalinclude:: ../../../perun-examples/payment-channel/client/handle.go
   :language: go
   :lines: 27-52

To accept the channel, we follow two steps:
First, we create the accept message, including the client's address and a random nonce.
This is done by simply calling `proposal.Accept()` on the proposal object.
Then we send the accept message via the responder `responder.Accept()`.

If this is successful, we call `startWatching()` to allow the client to react to disputes on the accepted channel automatically.
Finally, we add the `PaymentChannel` to the clients channel registry.

.. literalinclude:: ../../../perun-examples/payment-channel/client/handle.go
   :language: go
   :lines: 54-70

Handling Channel Updates
~~~~~~~~~~~~~~~~~~~~~~~~
For deciding how to handle incoming channel updates (off-chain!), we define `HandleUpdate()`.
You can define logic here that decides under which conditions an update is accepted or rejected.
In order to evaluate this, the current channel state `cur` given as `channel.State` and the proposed new state `next` given as `client.ChannelUpdate` come as arguments.
For accepting or rejecting the proposed update `client.UpdateResponder` `r` is given.

In our example, we will accept every update that increases our balance. Therefore, we perform the following steps:

#. Check if the type of asset is still the asset from the state before by calling `channel.AssetsAssertEqual()`.
#. Fetch our balance from the current state `cur` and our balance in the next state `next` via  `Allocation.Balance()`.
#. Compare these balances with `balance.Cmp()`, which subtracts the values. If the resulting value is positive, our balance increases.

Again, you are free to add any additional checks to the logic here to change the clients' behavior when accepting channel updates.

.. literalinclude:: ../../../perun-examples/payment-channel/client/handle.go
   :language: go
   :lines: 72-91

If all checks above pass, we accept the update by calling `.Accept()` on the `client.UpdateResponder`.

.. literalinclude:: ../../../perun-examples/payment-channel/client/handle.go
   :language: go
   :lines: 93-98


.. toctree::
   :hidden:
