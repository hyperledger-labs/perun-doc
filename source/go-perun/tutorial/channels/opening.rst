Opening
=======

Opening a payment channel works by defining the initial asset allocation, setting the
channel parameters, creating a proposal and sending that proposal to all participants.
The channel is open after all participants accept the proposal and finish the on-chain funding.

.. literalinclude:: ../../../perun-examples/simple-client/node.go
   :language: go
   :lines: 48-78

The `ProposeChannel` call blocks until *Alice* accepted and funded the channel, or rejected.

HandleProposal
^^^^^^^^^^^^^^

Clients must implement the channel proposal handler interface in order to respond to incoming channel proposals.

.. literalinclude:: ../../../perun-examples/simple-client/node.go
   :language: go
   :lines: 80-99

You can add additional check logic here but in our simple use case we always accept
incoming proposals. After the channel is open, both participants will have their `NewChannel` callback called.

NewChannel
^^^^^^^^^^

*go-perun* expects this handler to finish quickly. Use *go* routines if you want to do
time-intensive tasks. You should also start the :ref:`watcher <the-watcher>` as shown below:

.. literalinclude:: ../../../perun-examples/simple-client/node.go
   :language: go
   :lines: 101-110

.. warning::

   Starting the watcher is strongly advised. Otherwise *go-perun* will
   not react to malicious behavior of other participants and users risk losing funds.
