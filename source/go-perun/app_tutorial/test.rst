Test
====
We now create a simple test for our app channel client by setting up two clients, opening an app channel between them, and playing one round of Tic-Tac-Toe.
Everything in this section will take place in package ``main``.

.. code-block:: go

    package main

Utilities
---------

We construct helpers in ``util.go`` for contract deployment, client generation, and logging of balances.

.. note::
    These are very similar to the :ref:`payment channel setup <setupscenario>`; hence only the additions in ``deployContracts`` and ``setupGameClient`` are mentioned here.

    **Deploy contracts.**
    Besides the Adjudicator and Asset Holder, the ``TicTacToeApp.sol`` app contract is required to be deployed.
    Its go binding provides ``ticTacToeApp.DeployTicTacToeApp`` to realize this.

    **Setup game client.**
    The ``app`` and ``stake`` arguments are added here to satisfy the client's constructor ``client.SetupAppClient``.

Main routine
------------

An exemplary round of Tic-Tac-Toe is played.
We put the code of this section into ``main.go``.
Ultimately, you can run ``main.go`` to see the individual steps executing in your command line output.

**Configuration.**
We are using the same configuration as for the :ref:`payment channel example <payment-test-environment>`:
``chainURL`` and ``chainID`` identify the blockchain we want to run on. In our case, an instance of the local chain is provided by the *ganache-cli*.
Three private keys are required.
Some party deploying the contracts, and Alice & Bob who want to use the app channel.

.. literalinclude:: ../../perun-examples/app-channel/main.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/689b8cdfef8ef8fb527723d52e6ce36dfe1b661c/app-channel/main.go#L26>`__
    :language: go
    :lines: 26-34

**Contract deployment.**
We call ``deployContracts`` with the corresponding arguments to receive the ``adjudicator``, ``assetHolder``, and ``appAddress``.
Using ``appAddress`` we initialize a new ``TicTacToeApp``.

.. literalinclude:: ../../perun-examples/app-channel/main.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/app-channel/main.go#L39>`__
    :language: go
    :lines: 36-44

**Client setup.**
We create a new message bus via ``wire.NewLocalBus``, which will be used by the clients to communicate with each other.
Then we call the ``setupGameClient`` for both Alice and Bob.
The balance logger is initialized via ``newBalanceLogger`` and ``LogBalances`` prints the initial balance of both clients.

.. literalinclude:: ../../perun-examples/app-channel/main.go
    :language: go
    :lines: 46-55

**Open app channel and play.**
Alice opens a channel with ``OpenAppChannel`` with Bob, where she specifies the amount she wants to put into the channel.
Bob fetches the new channel from his registry by calling ``AcceptedChannel``.
Now everything is set up, and we let Alice and Bob play by calling ``Set`` alternately.

.. literalinclude:: ../../perun-examples/app-channel/main.go
    :language: go
    :lines: 57-79

**Dispute.**
Suppose Alice proposed her winning move with ``Set(1, 2)`` but Bob is malicious and did not accept this new state in an attempt to save his funds.
Alice uses ``ForceSet`` to enforce her winning game move then.
Bob cannot do anything to prohibit Alice from winning at this point because the adjudicator (with the corresponding on-chain ``validTransition`` logic) decides over Alice's proposed update.

.. literalinclude:: ../../perun-examples/app-channel/main.go
    :language: go
    :lines: 81-86

**Settle.**
Alice wins in our case, and we settle to conclude and withdraw the funds from the channel.
Finally, both clients shut down to free up the used resources.

.. literalinclude:: ../../perun-examples/app-channel/main.go
    :language: go
    :lines: 88-98

Run from command line
---------------------
We now execute our test case from the command line.

First, we start a local Ethereum blockchain.
We run *ganache-cli* exactly like we did in the :ref:`payment channel example <run_the_app>`.
Please make sure that the constants match the ones used in the client configuration.

.. code-block:: bash

    KEY_DEPLOYER=0x79ea8f62d97bc0591a4224c1725fca6b00de5b2cea286fe2e0bb35c5e76be46e
    KEY_ALICE=0x1af2e950272dd403de7a5760d41c6e44d92b6d02797e51810795ff03cc2cda4f
    KEY_BOB=0xf63d7d8e930bccd74e93cf5662fde2c28fd8be95edb70c73f1bdd863d07f412e
    BALANCE=10000000000000000000

    ganache-cli --host 127.0.0.1 --port 8545 --account $KEY_DEPLOYER,$BALANCE --account $KEY_ALICE,$BALANCE --account $KEY_BOB,$BALANCE --blockTime=5

Now run the tutorial application with:

.. code-block:: bash

    go run .

You should be able to observe  the following output:

.. note::
    Because we included a dispute, there is more chain interaction than in the optimistic case; therefore, we have multiple *adjudicator events*.
    The ``RegisteredEvent`` signals that the forced state got successfully registered on-chain.
    Following that, the ``ProgressedEvent`` is triggered, which signals on-chain progression.
    Finally, the ``ConcludedEvent`` occurs during settlement.

.. code-block:: none

    2022/03/24 09:44:40 Deploying contracts.
    2022/03/24 09:44:53 Setting up clients.
    2022/03/24 09:44:54 Client balances (ETH): [10 10]
    2022/03/24 09:44:54 Opening channel.
    2022/03/24 09:44:59 Start playing.
    2022/03/24 09:44:59 Alice's turn.
    2022/03/24 09:44:59
     | |x
     | |
     | |
    Next actor: 1

    2022/03/24 09:44:59 Bob's turn.
    2022/03/24 09:44:59
    o| |x
     | |
     | |
    Next actor: 0

    2022/03/24 09:44:59 Alice's turn.
    2022/03/24 09:44:59
    o| |x
     | |
    x| |
    Next actor: 1

    2022/03/24 09:44:59 Bob's turn.
    2022/03/24 09:44:59
    o| |x
     |o|
    x| |
    Next actor: 0

    2022/03/24 09:44:59 Alice's turn.
    2022/03/24 09:44:59
    o| |x
     |o|
    x| |x
    Next actor: 1

    2022/03/24 09:44:59 Bob's turn.
    2022/03/24 09:44:59
    o| |x
     |o|o
    x| |x
    Next actor: 0

    2022/03/24 09:44:59 Alice's turn.
    2022/03/24 09:45:03 Adjudicator event: type = *channel.RegisteredEvent, client = 0x6536425BE95A6661F6C6f68D709B6BE152785Df6
    2022/03/24 09:45:13 Adjudicator event: type = *channel.RegisteredEvent, client = 0x56FD289cEe714a5E471c418436EFA63E780D7a87
    2022/03/24 09:45:13
    o| |x
     |o|o
    x|x|x
    Next actor: 1

    2022/03/24 09:45:18 Adjudicator event: type = *channel.ProgressedEvent, client = 0x6536425BE95A6661F6C6f68D709B6BE152785Df6
    2022/03/24 09:45:19 Alice wins.
    2022/03/24 09:45:19 Payout.
    2022/03/24 09:45:19 Adjudicator event: type = *channel.ProgressedEvent, client = 0x56FD289cEe714a5E471c418436EFA63E780D7a87
    2022/03/24 09:45:24 Adjudicator event: type = *channel.ConcludedEvent, client = 0x6536425BE95A6661F6C6f68D709B6BE152785Df6
    2022/03/24 09:45:30 Adjudicator event: type = *channel.ConcludedEvent, client = 0x56FD289cEe714a5E471c418436EFA63E780D7a87
    2022/03/24 09:45:30 Client balances (ETH): [14.999242656 4.99990828]



With this, we conclude our app channel tutorial.