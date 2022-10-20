On-chain component
------------------
For the on-chain component we need to implement `Perun's Ethereum App interface <https://github.com/perun-network/perun-eth-contracts/blob/main/contracts/App.sol>`_.
We create the *Solidity* smart contract ``contracts/TicTacToeApp.sol``.
Valid game moves and winning conditions are defined here.

.. warning::
    The contract defines what transition is considered valid or not.
    All disputes regarding this are being solved here.
    Any possible exploit in this method breaks the app channel's security guarantees and put's funds at risk.

.. literalinclude:: ../../../perun-examples/app-channel/contracts/TicTacToeApp.sol
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/contracts/TicTacToeApp.sol#L17>`__
    :language: none
    :lines: 17-28

We set a few self-explanatory constants.

.. note::
    Some of these constants might seem unnecessary for our simple data structure, but they become handy in more complex cases, especially for more extensive data structures.

.. literalinclude:: ../../../perun-examples/app-channel/contracts/TicTacToeApp.sol
    :language: none
    :lines: 29-37

.. _on_chain_valid_transition:

Valid Transition
~~~~~~~~~~~~~~~~
We define ``validTransition`` to evaluate if a move is considered valid or not.
``Channel.Params`` ``params`` holds general app channel parameters like ``Channel.Params.challengeDuration`` and ``Channel.Params.participants``.
``Channel.State`` ``from`` and ``to`` hold the game state as ``Channel.State.appData`` and ``Channel.State.isFinal``.

.. literalinclude:: ../../../perun-examples/app-channel/contracts/TicTacToeApp.sol
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/contracts/TicTacToeApp.sol#L46>`__
    :language: none
    :lines: 39-52

**Check basic requirements.**
Is the number of participants as expected?
Is the provided ``appData`` of the expected length?
Is the callee also the actor of the last state?
Is the next actor indeed the opposite party?

.. literalinclude:: ../../../perun-examples/app-channel/contracts/TicTacToeApp.sol
    :language: none
    :lines: 53-58

**Check the grid.**
Like before, we require that exactly one field which was ``notSet`` in ``from`` now is in ``to`` and that no previously set field is overwritten.
If no field or more than one field is changed, we detect an invalid transition.

.. literalinclude:: ../../../perun-examples/app-channel/contracts/TicTacToeApp.sol
    :language: none
    :lines: 60-69

**Check win condition and balance.**
Then we come to the win condition and its effect on the subsequent balances of the parties.
The primary evaluation is handled by ``checkFinal``, which we define later.
Our evaluation must match with the proposed ``isFinal`` flag.

Additionally, we check that there is no change regarding the assets and the total locked balance between the old and new state.
If ``hasWinner`` is true, we expect a balance change.
Otherwise, we make sure that the balances remain unchanged.
In our logic, *the winner takes it all*.
In that sense, we calculate the expected balances and compare them to the proposed ones via ``requireEqualUint256ArrayArray``.

.. literalinclude:: ../../../perun-examples/app-channel/contracts/TicTacToeApp.sol
    :language: none
    :lines: 71-87

Check Final
~~~~~~~~~~~
We implement ``checkFinal``.
Like in the local app, we hard-code all possible win combinations in ``winningRows``.
We simply iterate over these and check via ``sameValue`` if one symbol ticks all three fields, hence winning the game.
If this is the case, we return the respective winner and ``isFinal`` and ``hasWinner`` as true.

.. literalinclude:: ../../../perun-examples/app-channel/contracts/TicTacToeApp.sol
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/contracts/TicTacToeApp.sol#L89>`__
    :language: none
    :lines: 89-109

If no winning party is found, we iterate over all fields on the grid.
If all happen to be ticked, we have a draw.
If not, the game is still ongoing. We return the respective flags for both cases.

.. literalinclude:: ../../../perun-examples/app-channel/contracts/TicTacToeApp.sol
    :language: none
    :lines: 111-118

Helpers
~~~~~~~
Finally we implement the two helper ``sameValue`` and ``requireEqualUint256ArrayArray``.

``sameValue`` takes the state's data ``d`` for accessing the grid and three fields as indices ``gridIndices``.
If these indices refer to ticked grid fields by the same player, we return ``true`` and the player's id.

.. literalinclude:: ../../../perun-examples/app-channel/contracts/TicTacToeApp.sol
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/contracts/TicTacToeApp.sol#L120>`__
    :language: none
    :lines: 120-128

``requireEqualUint256ArrayArray`` simply wraps ``Array.requireEqualUint256Array`` to compare two-dimensional arrays ``a`` and ``b``.
We do not return anything here because a ``require`` is used to compare, therefore aborting the call if inequality is detected.

.. literalinclude:: ../../../perun-examples/app-channel/contracts/TicTacToeApp.sol
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/contracts/TicTacToeApp.sol#L130>`__
    :language: none
    :lines: 130-141

Compiling
~~~~~~~~~
The app's contract must be compiled, and go bindings must be generated to enable interaction from within *golang*.
For simplicity, ``contracts/generated/ticTacToeApp/ticTacToeApp.go`` is given, so you don't have to compile it for yourself.

.. note::
    If you want to make changes to the contract, the shell script ``contracts/generate.sh`` streamlines the compilation and binding generation.
    For using the script, additional dependencies are required: The *Solidity* compiler `solc <https://docs.soliditylang.org/en/latest/installing-solidity.html>`_  and `geth <https://geth.ethereum.org/docs/install-and-build/installing-geth>`_.