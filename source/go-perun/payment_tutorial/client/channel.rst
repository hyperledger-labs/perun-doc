.. _client-channel:

Channel
=======

We define a channel object for each type of state channel a client participates in to implement channel-specific client-to-channel actions.
In our payment channel example, this is quite simple:
We want to send a payment to the opposite party, and we want to eventually (& proactively) settle the payment channel.
We put this functionality in `client/channel.go`.

As the base, we always use `client.Channel` that comes with go-perun.
We wrap this into a new `PaymentChannel` object for our payment use case.

.. literalinclude:: ../../../perun-examples/payment-channel/client/channel.go
   :language: go
   :lines: 11-23


Send Payment
~~~~~~~~~~~~~
Sending a payment is only a proposal to change the balances of a channel so that the sender's balance is reduced and the receiver's balance is increased.
By doing the opposite, we can realize payment requests.
We create `SendPayment()` to implement our basic payment logic here, which expects the `amount` to be transferred to the peer.

We use `channel.UpdateBy()` for conveniently proposing our desired update to the channel's `state`.
Although we are not at risk here, note that any update must maintain the overall sum of funds inside the channel. Otherwise, the update is blocked.
We do not need to think about this here because go-perun's `state.Allocation.TransferBalance()` automatically subtracts the given `amount` from the proposer and adds it to the receiver. It ensures the right balance afterward.

.. literalinclude:: ../../../perun-examples/payment-channel/client/channel.go
   :language: go
   :lines: 25-39

.. _client-channel-settle:

Settle Channel
~~~~~~~~~~~~~~
As stated before in the :ref:`Protocol chapter <settle>`, settling a channel is done in two steps: Conclude and Withdraw.
These steps are already realized by go-perun in `channel.Settle()`.
However, for fast and cheap settlement, the channel needs to be finalized first.

Therefore, we create `Settle()` and call `channel.UpdateBy()` again to get access to the channel `state` and set the `IsFinal` flag to `true`.
If the peer already finalizes the channel, we skip this.

After successful finalization, there can no longer be any changes to the channel.
We can call `channel.Settle()`, which ultimately closes the payment channel and withdraws our final balance.

.. literalinclude:: ../../../perun-examples/payment-channel/client/channel.go
   :language: go
   :lines: 41-62

.. toctree::
   :hidden:

