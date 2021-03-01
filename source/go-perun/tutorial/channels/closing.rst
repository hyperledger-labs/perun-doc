Closing
=======

Closing a channel can be done in two ways, either cooperative or non-cooperative. This example focuses on the cooperative way. As you would expect from closing an off-chain
channel, the on-chain balances will be updated accordingly. But before that can happen
there are some other steps that we will go through first.

.. _the-watcher:

The Watcher
^^^^^^^^^^^

*go-perun* reacts automatically to on-chain events of a channel as long as its `watcher` routine is running. You should start the watcher in the `NewChannel` handler in a new
go-routine since `channel.Watch`_ blocks.

.. _finalizing:

Finalizing
^^^^^^^^^^

The state of a channel in *go-perun* has a public boolean `IsFinal`_ flag.
Final states can directly be closed on-chain without raising a dispute.
This allows for a faster collaborative closing process.
As soon as a channel has a final state, we call it *finalized* since it can not
be updated anymore. Have a look again at :ref:`updating` on how to do it.

Registering
^^^^^^^^^^^

Registering a channel means pushing its latest state onto the `Adjudicator`.
A registered channel state is openly visible on the blockchain. This should only be done
when a channel should be closed or disputed.

.. note::

   Registering non-finalized channels will raise a dispute.

Settlement
^^^^^^^^^^

Settlement is the last step in the lifetime of a channel. It consists of two steps:
*conclude* and *withdraw*. *go-perun* takes care of both when `channel.Settle`_ is called. 

*conclude* waits for any on-chain disputes to be resolved and then calls the `Adjudicator`
to close the channel. After this is done, the channel can be *withdrawn*. This is done only
once by one of the channel participants.

The last step is for each participant to *withdraw* their funds from the `AssetHolder`.
The balance that can be withdrawn is the same as the final balance of the channel.
Ethereum transaction fees still apply.

.. warning::

   Trying to settle a channel that was not registered before is not advised and
   can result in a dispute.

Keep in mind that we already *finalized* the channel in the update that we sent.
We therefore just need to *register* and *settle* which looks like this:

.. literalinclude:: ../../../perun-examples/simple-client/node.go
   :language: go
   :lines: 130-147

The other participant would then have its `AdjudicatorEvent` handler called with a
`ConcludedEvent`_ and should then also execute `closeChannel`.

.. literalinclude:: ../../../perun-examples/simple-client/node.go
   :language: go
   :lines: 149-155

.. _IsFinal: https://pkg.go.dev/perun.network/go-perun/channel#State
.. _channel.Settle: https://pkg.go.dev/perun.network/go-perun/client#Channel.Settle
.. _channel.Watch: https://pkg.go.dev/perun.network/go-perun/client#Channel.Watch
.. _ConcludedEvent: https://pkg.go.dev/perun.network/go-perun/channel#ConcludedEvent
