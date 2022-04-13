.. _app_client:

Client
======
In this section, we describe the app channel client that is used for opening a channel with the Tic Tac Toe app instantiated.
Much of the app channel client is similar to the :ref:`payment channel client <payment_client>`, and we will reuse some of the code here. The code will be placed in package ``client``.

.. code-block:: go

    package client

Constructor
-----------
The main part of our app channel client is placed in ``client/client.go``.
Our client is of type ``AppClient``, which is similar to the ``PaymentClient``.
The only additional parameters here are ``stake`` and ``app``.

.. literalinclude:: ../../perun-examples/app-channel/client/client.go
    :emphasize-lines: 6,7
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/client/client.go#L41>`__
    :language: go
    :lines: 40-48


``SetupAppClient`` is extended accordingly.
For an explanation of its logic, please have a look at the description of :ref:`the payment client constructor <payment_client_constructor>`.

Open channel
------------
In the channel opening procedure ``OpenAppChannel``, we need to perform two changes to adapt to our app channel use case.

On the one hand, we now expect both parties to deposit matching funds to ensure equal awards for the winner.
We realize this by putting ``stake`` for both ``channel.Bal`` indices when calling ``Allocation.SetAssetBalances``.

.. literalinclude:: ../../perun-examples/app-channel/client/client.go
    :emphasize-lines: 7-10
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/client/client.go#L117>`__
    :language: go
    :lines: 116-125

On the other hand, we include our application ``app`` in the channel proposal.
We call ``client.WithApp`` provided by *go-perun*, configuring the given ``app`` with the desired initial data.
How ``app.InitData`` generates the initial data is described in the :ref:`app section <app_generate_initial_state>`.

.. important::
    Keep in mind the criticality of the :ref:`challenge duration <payment_challenge_duration_warning>` parameter.
    Here it also defines the amount of time players have for their turn once the channel is disputed on-chain.

.. literalinclude:: ../../perun-examples/app-channel/client/client.go
    :emphasize-lines: 4, 5, 12
    :language: go
    :lines: 127-154

Handle proposal
~~~~~~~~~~~~~~~
Our app channel client's handler provides callbacks for handling incoming app channel proposals and updates in ``client/handle.go``.

.. note::
    This part is again very similar to the payment channel example with the difference that we now expect a specific app channel that receives equal funding from both sides.
    For more details, please have a look at the description of the :ref:`payment channel proposal handler <payment_client_handle_proposals>`.

To ensure that the proposal includes the correct app, we check if the proposal's contract app address equals the one the client expects.
Furthermore, we check that the funding agreement, ``lcp.FundingAgreement``, corresponds to the expected stake.

.. literalinclude:: ../../perun-examples/app-channel/client/handle.go
    :emphasize-lines: 10-12, 30,31
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/client/handle.go#L26>`__
    :language: go
    :lines: 25-61

As in the payment channel example, we create the accept message, send it, and start the on-chain watcher.

.. literalinclude:: ../../perun-examples/app-channel/client/handle.go
    :language: go
    :lines: 63-78

Handle Update
~~~~~~~~~~~~~
We don't need to do much here in the app channel case for handling state updates.
We can accept every update because the app's :ref:`valid transition function <app_validate_transition>` ensures that the transition is valid.

.. literalinclude:: ../../perun-examples/app-channel/client/handle.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/client/handle.go#L81>`__
    :language: go
    :lines: 80-88

With ``HandleAdjudicatorEvent`` we formulate a callback for smart contract events, only printing these in the command line output.

.. _app_client_channel:

App channel
-----------
We implement the type ``TicTacToeChannel`` that wraps a Perun channel and provides functions to interact with the app channel.
We put this functionality in ``client/channel.go``.

.. literalinclude:: ../../perun-examples/app-channel/client/channel.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/client/channel.go#L13>`__
    :language: go
    :lines: 12-15

.. _app_client_channel_set:

Set
~~~
We create ``Set``, which expects ``x`` and ``y`` that indicate where the client wants to put its symbol on the grid.

We use ``channel.UpdateBy`` for proposing our desired update to the channel's ``state``.
With ``state.App``, we fetch the app that identifies the channel's application and check if it is of the expected type.
Then we call ``TicTacToeApp.Set``, which will manipulate ``state.Data`` to include the desired turn.
``state.Data`` holds all app-specific data, reflecting our Tic-Tac-Toe game's current game state.
We go into more detail about this in the :ref:`app description <app_set>`.

.. literalinclude:: ../../perun-examples/app-channel/client/channel.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/client/channel.go#L23>`__
    :language: go
    :lines: 22-35

Force Set
~~~~~~~~~
``ForceSet`` is similar to ``Set`` but uses *go-perun*'s ``channel.ForceUpdated`` instead of ``channel.UpdateBy``.
This forced update bypasses the state channel and registers a game move directly on-chain, which is needed in case of a dispute.

.. note::

    Suppose party *A* sent an updated game state to malicious party *B*.
    *A*'s game move is valid and would lead to *A* winning the game, therefore gaining access to the locked funds.
    Now *B* could potentially refuse to accept this valid transition in an attempt not to lose the game.
    In this case, *A* utilizes ``ForceSet`` with its proposed update to enforce the game rules on-chain without full consensus and win the game properly.

.. literalinclude:: ../../perun-examples/app-channel/client/channel.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/client/channel.go#L38>`__
    :language: go
    :lines: 37-55

Settle Channel
~~~~~~~~~~~~~~
Settling the channel is quite similar to the way :ref:`we already implemented <payment_client_settle>` in the payment channel tutorial.
But in our case, we can skip the finalization part because we expect the app logic to finalize the channel after the winning move.

.. literalinclude:: ../../perun-examples/app-channel/client/channel.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/client/channel.go#L58>`__
    :language: go
    :lines: 57-68

Utilities
---------
The utility functions ``startWatching()``, ``AcceptedChannel()``, ``Shutdown()``, ``CreateContractBackend()``, ``EthToWei()`` and ``WeiToEth()`` remain untouched and are are taken over from their :ref:`definitions <client_utility>` in the payment channel example.
These functionalities are implemented in ``client/client.go`` and ``client/util.go``.