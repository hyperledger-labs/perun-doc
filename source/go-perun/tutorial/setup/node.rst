Client Node
===========

The interactions with *go-perun* channels are managed by a `Client` object.
This `Client` object is of central importance. All the foregone setup was only means
to be able to create it since the `client.New`_ function needs all of them as input.
To manage all state we will create a `node` struct:

.. literalinclude:: ../../../perun-examples/simple-client/node.go
   :language: go
   :lines: 24-36

It is named `node` to not be mixed up with a *go-perun* `Client`.

Callbacks
---------

*go-perun* uses callbacks to forward interactions from the channels to the user.
There are four callbacks that the user needs to provide; `Proposal`, `Update`, `NewChannel` and `AdjudicatorEvent`. *go-perun* expects the user to implement two interfaces `ProposalHandler`_ and `UpdateHandler`_. The `NewChannel` and `AdjudicatorEvent` callbacks are implemented as function pointers.
We define all these callbacks on our `node` but leave them empty for now:

The `Proposal` callback is called whenever the `Client` receives a channel
proposal. The user can then accept or reject the proposal depending
on whether he wants to open that channel.

.. literalinclude:: ../../../perun-examples/simple-client/node.go
   :language: go
   :lines: 70

The `Update` callback queries the user whether he wants to accept the channel update
that was proposed to him.

.. literalinclude:: ../../../perun-examples/simple-client/node.go
   :language: go
   :lines: 117

`NewChannel` is used whenever a new channel was successfully opened.

.. literalinclude:: ../../../perun-examples/simple-client/node.go
   :language: go
   :lines: 91

`AdjudicatorEvent` is called when the `watcher` received an on-chain event from the
`Adjudicator`. This will be relevant for closing a channel and handling disputes.

.. literalinclude:: ../../../perun-examples/simple-client/node.go
   :language: go
   :lines: 149

.. _client.New: https://pkg.go.dev/perun.network/go-perun/client#New
.. _ProposalHandler: https://pkg.go.dev/perun.network/go-perun/client#ProposalHandler
.. _UpdateHandler: https://pkg.go.dev/perun.network/go-perun/client#UpdateHandler
.. _ChannelProposalAccept: https://pkg.go.dev/perun.network/go-perun/client#ChannelProposalAccept
.. _ChannelProposalAccept: https://pkg.go.dev/perun.network/go-perun/client#ChannelProposalAccept
.. _Accept: https://pkg.go.dev/perun.network/go-perun/client#LedgerChannelProposal
