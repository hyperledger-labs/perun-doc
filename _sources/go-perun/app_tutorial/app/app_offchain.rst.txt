Off-chain component
-------------------

Here we need to implement `Perun's Core App interface <https://github.com/perun-network/go-perun/blob/main/channel/app.go>`_.

Data
~~~~
Before we implement the channel app, we define the game's states.
We put this in ``app/data.go``.

The game state is handled in ``TicTacToeAppData``, which implements *go-perun*'s ``Data`` interface.
``NextActor`` represents the next party expected to make a move, and ``Grid`` represents the Tic-Tac-Toe 3x3 grid.
The ``Grid`` indices are defined from the upper left to the lower right.

.. literalinclude:: ../../../perun-examples/app-channel/app/data.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/app/data.go#L17>`__
    :language: go
    :lines: 12-20

Encode
......
The ``Data`` interface requires that ``TicTacToeData`` can be encoded onto an ``io.Writer`` via ``Encode``.
This method writes our game data to the given data stream.
It is needed to push the local game data to the smart contract.
Decoding will take place in the :ref:`app implementation <app_decoding>`.

.. literalinclude:: ../../../perun-examples/app-channel/app/data.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/app/data.go#L32>`__
    :language: go
    :lines: 31-40

Manipulate Grid
...............
With ``Set``, we allow the manipulation of ``TicTacToeData``.
It takes coordinates ``x``, ``y`` , and an index identifying the actor ``actorIdx`` to realize a specific move.
To get the grid field index from ``x`` and ``y``, we calculate :math:`i = y*3+x` and set ``Grid[i]`` to the actor's icon.
Then we update ``TicTacToeAppData.NextActor`` with ``calcNextActor``.

.. literalinclude:: ../../../perun-examples/app-channel/app/data.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/app/data.go#L48>`__
    :language: go
    :lines: 48-55

String and Clone
................
We implement a simple ``String`` method that prints the match field into the command line to visualize ``TicTacToeAppData.Grid``.
This will be handy for following the game's progress later on.

.. literalinclude:: ../../../perun-examples/app-channel/app/data.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/app/data.go#L22>`__
    :language: go
    :lines: 22-29

To allow copying ``TicTacToeAppData``, we provide ``Clone``.

.. literalinclude:: ../../../perun-examples/app-channel/app/data.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/app/data.go#L43>`__
    :language: go
    :lines: 42-46

Utilities
~~~~~~~~~
Before we go on with the app implementation, we need to define a few utilities.
Most are trivial; therefore, we will only look at the important ones here.
These app utilities are implemented in ``app/util.go``.

Same Player
...........
``samePlayer`` accepts a list of indices that refer to particular fields on the Tic-Tac-Toe grid and checks if the same player marked these fields.

Start by fetching the value of the first gird index.
Then we compare this with the values of the other fields.
If one of the fields is not set or is set but with another value, we return ``false``.
If all fields match, we return ``true`` with the respective ``PlayerIndex``.

.. literalinclude:: ../../../perun-examples/app-channel/app/util.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/app/util.go#L99>`__
    :language: go
    :lines: 99-114

Check Final
...........
With ``CheckFinal``, we take the current state of the match field and evaluate if the game is finalized, hence if there is a winner.

**Define the winning condition.**
We start by listing all winning possibilities in an array.

.. literalinclude:: ../../../perun-examples/app-channel/app/util.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/app/util.go#L71>`__
    :language: go
    :lines: 71-81

**Check for a win.**
Then we check if one of these combinations is held by one player via ``TicTacToeAppData.samePlayer``.
If there is a player, we find a winner and return ``true``, including the winner's index ``idx``.

.. literalinclude:: ../../../perun-examples/app-channel/app/util.go
    :language: go
    :lines: 83-88

**Check for a draw.**
If we cannot find a winner, we check if there is a draw or if the game is still in progress.
In case of a draw, we return ``true`` with no player index.
Note that the winning/draw check order is essential because there are cases where all grid values are set, but there is one winner.

.. literalinclude:: ../../../perun-examples/app-channel/app/util.go
    :language: go
    :lines: 90-97

Compute Final Balances
......................
Finally, we want to implement a function ``computeFinalBalances`` that computes the final balances based on the ``winner`` of the game.

First, we calculate the index of the ``loser``.
Notice that the way it is presented in code only works for two-party use cases.
Then we loop through all the assets (in our case, it will only be one: Ethereum).
In our case, *the winner takes it all*. Therefore, we add the loser's balance to the winner's and set the balance of the loser to zero.
Ultimately we return the final balance ``finalBals``.

.. literalinclude:: ../../../perun-examples/app-channel/app/util.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/app/util.go#L162>`__
    :language: go
    :lines: 162-170

App
~~~
We create the ``TicTacToeApp`` in ``app/app.go``, which implements *go-perun*'s ``App`` interface that provides the base.

.. note::
    The ``App`` interface comes in two flavors: As ``StateApp`` or ``ActionApp``

    - The ``StateApp`` allows for simple one-sided state updates. This means that one party makes a move, and the state is updated accordingly (e.g., during the move of *A*, only input of *A* is needed to form the next state).
    - The ``ActionApp`` is a more fine-grained type. It allows to collect actions from all participants to apply those for a new state (e.g., *A* and *B* both contribute to forming the next state).

In our case, the ``StateApp`` is sufficient because, for a Tic-Tac-Toe game, we only need state updates from one side at a time.
We implement this in ``app/app.go``.

Data structure
..............
We implement the off-chain component as type ``TicTacToeApp``, which holds an address that links the object to the respective smart contract.

.. literalinclude:: ../../../perun-examples/app-channel/app/app.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/app/app.go#L29>`__
    :language: go
    :lines: 28-37

.. _app_generate_initial_state:

Initialization
..............
We create a getter for the app's smart contract address ``Addr`` with ``Def``.

.. literalinclude:: ../../../perun-examples/app-channel/app/app.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/app/app.go#L40>`__
    :language: go
    :lines: 39-42

Further, we create ``InitData``, which wraps the ``TicTacToeAppData`` constructor to generate a new match field with a given party ``firstActor`` as the first to be allowed to make a move.

.. literalinclude:: ../../../perun-examples/app-channel/app/app.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/app/app.go#L44>`__
    :language: go
    :lines: 44-48

.. _app_decoding:

Decode
......
As ``Encode`` is required to encode the game data into a channel state, ``Decode`` is needed for converting a game state into a ``TicTacToeAppData`` format for us to use.
We put the decoder in ``app/util.go``.

First, we create an empty ``TicTacToeAppData`` object that we want to fill with the data (``nextActor``, ``grid``) given by the ``io.Reader``.
We fetch the actor by calling ``readUInt8``, which reads the first byte of the given data stream.
Then we fetch the grid values by calling ``readUInt8Array``, which reads the next nine bytes.
Finally, we convert the bytes to their respective field values by calling ``makeFieldValueArray``.

.. literalinclude:: ../../../perun-examples/app-channel/app/app.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/app/app.go#L51>`__
    :language: go
    :lines: 50-66

Validate Initial State
......................
We will need to identify if an initial state is valid or not.
Hence, we create ``ValidInit`` that takes the channel's parameters ``channel.Params`` and a channel state ``channel.State`` as arguments.
If the given arguments do not match the expected ones for a valid app channel initialization, it should return an error.

#. **Channel participants.** Check if the number of actual channel participants matches the expected participants.
#. **Game data.** Validate the data type of the ``channel.State``'s data. It must be of type ``TicTacToeAppData``.
#. **Grid.** The grid must be empty. This is easily checkable by creating a new instance of ``TicTacToeAppData`` and comparing its gird with the given one.
#. **Finalization.** Verify that the channel state is not finalized. Remember that a final state cannot be further progressed. Therefore it would not make sense to accept one here.
#. **Actor index.** Validate the index of the ``NextActor``. If no deviations are found, ``nil`` is returned.

.. literalinclude:: ../../../perun-examples/app-channel/app/app.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/app/app.go#L69>`__
    :language: go
    :lines: 68-92

.. _app_validate_transition:

Validate Transitions
....................
``ValidTransition`` is an important part of the off-chain app implementation in which we check locally if a given game move is valid or not.
The method takes the channel's parameters ``channel.Params``, the old and (proposed) new channel state ``channel.State``, and the actor index as arguments.

.. warning::
    A bug in the valid transition function can result in fraudulent state transitions (e.g., a game move that is against the rules), potentially putting the client's funds at risk.

.. note::
    Note that this part will only affect the detection of invalid transitions.
    Even more critical is the on-chain ``validTransition`` :ref:`function <on_chain_valid_transition>`, because it ultimately decides what we can enforce.

**Validate data type.**
Check if the given ``Data`` included in the ``channel.State``'s is of the expected type.

.. literalinclude:: ../../../perun-examples/app-channel/app/app.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/app/app.go#L95>`__
    :language: go
    :lines: 94-109

**Validate actor.**
The proposing actor must differ from the actor of the old state because the game moves are expected to be alternating.
The actor for the next state must match the result of ``calcNextActor`` given the previous actor.

.. literalinclude:: ../../../perun-examples/app-channel/app/app.go
    :language: go
    :lines: 111-123

**Validate turn.**
We want to detect fraudulent or invalid turns here and look at three aspects:
*Value*: Is the set field value a possible one?
*Overwrite*: Does the set field value overwrite another set field?
*Fields*: Did none/more than one field change?

.. literalinclude:: ../../../perun-examples/app-channel/app/app.go
    :language: go
    :lines: 125-144

**Validate finalization.**
Finally, we check if the proposed state transition resulted in a final state (one party winning or a draw).
We do this by calling ``CheckFinal`` on the proposed data and comparing it with final state claimed by the proposal.

Depending on this, we check if the correct balances are included.
For this, we calculate the balances on our own via ``computeFinalBalances`` and compare the result with the proposal.

If all the mentioned checks pass, we accept the transition by returning ``nil``.

.. literalinclude:: ../../../perun-examples/app-channel/app/app.go
    :language: go
    :lines: 146-159

.. _app_set:

Game Move
.........
``Set`` is responsible for creating the state inside the client's ``Set`` :ref:`method <app_client_channel_set>`.
Therefore, we get the ``channel.State``, ``x``, ``y`` position, and actor index as arguments.

We again start by making a basic check that the state's app ``Data`` we want to manipulate is indeed of type ``TicTacToeAppData``.
Then we call ``TicTacToeApp.Set`` to perform the manipulation.
Finally, we check if the move eventually lets the client win the game.
We again use ``CheckFinal`` to compute the respective balances via ``computeFinalBalances`` in case a ``winner`` is found.

.. literalinclude:: ../../../perun-examples/app-channel/app/app.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/app/app.go#L161>`__
    :language: go
    :lines: 161-177
