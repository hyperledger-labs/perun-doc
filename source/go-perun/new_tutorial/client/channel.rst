.. _client-channel:

Channel
===============

We define a channel object for each type of state-channel a client participates in to implement channel-specific client-to-channel actions.
In our payment-channel example, this is quite simple:
We want to send a payment to the opposite party, and we want to eventually (& proactively) settle the payment-channel afterward.
We put this functionality in `client/channel.go`.

As the base, we always use `client.Channel` that comes with go-perun.
We wrap this into a new `PaymentChannel` object for our payment use case.

.. code-block:: go

    // PaymentChannel is a wrapper for a Perun channel for the payment use case.
    type PaymentChannel struct {
        ch *client.Channel
    }

    // newPaymentChannel creates a new payment channel.
    func newPaymentChannel(ch *client.Channel) *PaymentChannel {
        return &PaymentChannel{ch: ch}
    }

Send Payment
~~~~~~~~~~~~~
Sending a payment is only a proposal to change the balances of a channel so that the balance of the sender is reduced and the balance of the receiver is increased.
We create `SendPayment()` to implement our basic payment logic here.
As parameters `SendPayment()` expects the type of asset `asset` and of which quantity `amount` it should be transferred to the peer.

We use `channel.UpdateBy()` for conveniently proposing our desired update to the channel's `state`.
Although we are not at risk here, note that any update must maintain the overall sum of funds inside the Channel. Otherwise, the update is blocked.
We don't need to think about this here because go-perun's `state.Allocation.TransferBalance()` automatically subtracts the given `amount` from the proposer and adds it to the receiver. It ensures the right balance afterward.

.. code-block:: go

    // SendPayment sends a payment to the channel peer.
    func (c PaymentChannel) SendPayment(asset channel.Asset, amount uint64) {
        // Transfer the given amount from us to peer.
        // Use UpdateBy to update the channel state.
        err := c.ch.UpdateBy(context.TODO(), func(state *channel.State) error { // We use context.TODO to keep the code simple.
            ethAmount := new(big.Int).SetUint64(amount)
            state.Allocation.TransferBalance(proposerIdx, receiverIdx, asset, ethAmount)
            return nil
        })
        if err != nil {
            panic(err) // We panic on error to keep the code simple.
        }
    }


Settle Channel
~~~~~~~~~~~~~~
As stated before in the Protocol chapter, settling a channel is done in two steps: Conclude and Withdraw.
These steps are already realized by go-perun in `channel.Settle()`.
But for fast and cheap settlement, the channel needs to be finalized first.

Therefore, we create `Settle()` and call `channel.UpdateBy()` again to get access to the channel `state` and set the `IsFinal` flag to `true`.
After successful finalization, there cannot be any changes to the channel anymore. We can call `channel.Settle()`, which ultimately closes the payment channel and withdraws our final balance.

.. code-block:: go

    // Settle settles the payment channel and withdraws the funds.
    func (c PaymentChannel) Settle() {
        // Finalize the channel to enable fast settlement.
        err := c.ch.UpdateBy(context.TODO(), func(state *channel.State) error {
            state.IsFinal = true
            return nil
        })
        if err != nil {
            panic(err)
        }

        // Settle concludes the channel and withdraws the funds.
        err = c.ch.Settle(context.TODO(), false)
        if err != nil {
            panic(err)
        }

        // Close frees up channel resources.
        c.ch.Close()
    }
