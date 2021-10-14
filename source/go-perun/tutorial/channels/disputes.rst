.. _disputes :

Disputes
========

A *dispute* occurs when the channel participants cannot agree on the current state.
Say for example *Bob* is sure that he has 5 *ETH* but *Alice* insists that he only has 4 *ETH*.

Disputes are resolved on-chain.
The Perun protocols guarantee that the most recent state, agreed by all channel participants, can be redeemed.
Disputes are handled by the `Adjudicator` contract which determines the valid state by comparing the version numbers of the provided channel states.

A dispute is raised as soon as one participant registers a non-final state in the
`Adjudicator`. The other participant then has `challengeDuration`-seconds time to react by submitting a newer state to prove that he is honest and knows a newer valid state.
If the other participant is not able to do this, he loses the dispute and the first state is
accepted as final. The disputed channel is then *settled* and therefore closed.

.. note::

   The `challengeDuration` is part of the `channel proposal`_ and is agreed upon by
   both participants.

.. _channel proposal: https://pkg.go.dev/perun.network/go-perun/client#NewLedgerChannelProposal
