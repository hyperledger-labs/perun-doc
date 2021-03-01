Opening
=======

Opening a state channel works by defining the initial asset allocation, setting the
channel parameters, creating a proposal and sending that proposal to all participants.
The channel is open after all participants accept the proposal and finish the on-chain funding.

It looks like this:

.. literalinclude:: ../../../perun-examples/simple-client/node.go
   :language: go
   :lines: 38-68

The `ProposeChannel` call blocks until *Alice* either accepted or rejected the channel
and funded it.

.. warning::

   The channel that is returned by `ProposeChannel` should only be used to retrieve
   its *id*.

HandleProposal
^^^^^^^^^^^^^^

An example Proposal handler looks like this:

.. literalinclude:: ../../../perun-examples/simple-client/node.go
   :language: go
   :lines: 70-89

You can add additional check logic here but in our simple use case we always accept
incoming proposals. After the channel is open, both participants will have their `NewChannel` callback called.

.. warning:: The `Channel` that `ProposalResponder.Accept`_ returns should only be used to retrieve its *ID*.

NewChannel
^^^^^^^^^^

*go-perun* expects this handler to finish quickly. Use *go* routines if you want to do
time-intensive tasks. You should also start the :ref:`watcher <the-watcher>` as shown below:

.. literalinclude:: ../../../perun-examples/simple-client/node.go
   :language: go
   :lines: 91-100

.. note::

   Starting the watcher is not mandatory but strongly advised. *go-perun* can otherwise
   not react to malicious behavior of other participants.

.. _ProposalResponder.Accept: https://pkg.go.dev/perun.network/go-perun/client#ProposalResponder.Accept
