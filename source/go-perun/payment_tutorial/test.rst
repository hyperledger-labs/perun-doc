Test
====

We now create a simple test for our payment channel client.
We set up two clients, open a channel between them, perform several off-chain payments, and then close the channel.

Everything in this section will take place in package ``main``.

.. code-block:: go

    package main

.. _setupscenario:

Setup
-----

We construct a few helper functions that will cover the contract deployment, client generation, and logging of balances in the command line.
We put the code of this section into ``util.go``

.. _deploy-contracts:

Deploy Contracts
................

*Go-perun*'s Ethereum backend uses two on-chain contracts: the Adjudicator and the Asset Holder.
They are written in the contract language of Ethereum, `Solidity <https://docs.soliditylang.org/en/latest/>`_, and are part of *go-perun*'s Ethereum backend.

Each contract must be deployed before it can be used.
Usually, you would assume that they are already deployed and the addresses are known in advance.
But since this is a complete example for a local chain, we must deploy them.

*Go-perun* uses one contract per asset on top of the Ethereum blockchain.
In this example, we only use the ``ETHAssetHolder``, which is used for Ether, the native currency in Ethereum.
ERC20 Tokens are supported via the ``ERC20AssetHolder``.

We define ``deployContracts`` that gets as input a ``nodeURL``, ``chainID``, and the ``privateKey`` of the deployer.
We first parse the secret key in hexadecimal format and then create an instance of *go-perun*'s simple wallet by calling ``swallet.NewWallet``.
We then create a contract backend that will be used for deployment and define the deployer account.

.. literalinclude:: ../../perun-examples/payment-channel/util.go
   :language: go
   :lines: 33-44
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel/util.go#L34>`__

Using the contract backend ``cb``, we then deploy the ``Adjudicator`` and the ``AssetHolderETH`` via *go-perun*'s ``DeployAdjudicator`` and ``DeployETHAssetholder``.
Note that the Adjudicator must be deployed first because the asset holder depends on it.
Finally, we return both addresses.

.. literalinclude:: ../../perun-examples/payment-channel/util.go
   :language: go
   :lines: 46-59


Client setup wrapper
....................

We create a simple wrapper that helps us setting up a payment channel client.
It parses a given private key in hexadecimal format and creates a new wallet containing that key.
The wallet is then used with the other required arguments to call ``SetupPaymentClient`` for generating a new ``PaymentClient``

.. literalinclude:: ../../perun-examples/payment-channel/util.go
   :language: go
   :lines: 61-92
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel/util.go#L62>`__

Logging Balances
................
For seeing the effects of our off-chain payments, we implement a method for printing a client's balance to the standard output.
For this, we create a new type ``balanceLogger``, which simply wraps an ``ethclient.Client`` that will be used for reading account balance from the blockchain.

.. literalinclude:: ../../perun-examples/payment-channel/util.go
   :language: go
   :lines: 94-106
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel/util.go#L95>`__

We implement the logging of balances with ``LogBalances`` that takes a sequence of account addresses as input.
For each address, the balance is fetched via go-ethereum's ``BalanceAt``.

.. literalinclude:: ../../perun-examples/payment-channel/util.go
   :language: go
   :lines: 108-119
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel/util.go#L109>`__

Run
---

Finally, we want to use our preliminary work to perform a test run by instantiating the clients and performing a simple payment over a channel.
We put the code of this section into ``main.go``
Ultimately, you can run ``main.go`` to see the individual steps executing in your command line output.

We implement our scenario by first setting all necessary constants and then constructing our test case in the ``main`` function.

.. _payment-test-environment:

Environment
...........

As we mentioned earlier, we need the ``chainURL`` and ``chainID`` to identify the blockchain we want to work with.
In this case, we use the standard values used by *ganache-cli*.
Additionally, we require three private keys.
On the one hand, a party that is deploying the contracts.
On the other hand, Alice and Bob that want to use our payment channel.

.. literalinclude:: ../../perun-examples/payment-channel/main.go
   :language: go
   :lines: 23-32

Main function
.............
The ``main`` function implements the following steps.

#. We start with the deployment of the contracts by calling ``deployContracts`` with the corresponding arguments. This supplies us with the ``adjudicator`` and ``assetHolder`` addresses.
#. Next, we create a new message bus via ``wire.NewLocalBus``, which will be used by the clients to communicate with each other. Then we call the ``setupPaymentClient`` function for both Alice and Bob.
#. Then the balance logger is initialized via ``newBalanceLogger`` and ``LogBalances`` prints the initial balance of both clients.
#. Further, Alice opens a channel with ``OpenChannel`` with Bob, where she specifies the amount of funds that she wants to put into the channel. Bob fetches the new channel from his channel registry by calling ``AcceptedChannel``.
#. Now everything is set up, and we let Alice and Bob exchange a few Ether back and forth.
#. We print the balances and let Alice settle to conclude and withdraw her funds from the channel. Bob also settles to withdraw his funds directly.
#. Finally, both clients shut down to free up the used resources.

.. literalinclude:: ../../perun-examples/payment-channel/main.go
   :language: go
   :lines: 33-73
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel/main.go#L37>`__

.. _run_the_app:

Run from the command line
.........................
We now execute our test program from the command line.

First, we start a local Ethereum blockchain.
We run *ganache-cli* with pre-funded accounts using the command below.
Please make sure that the constants match the ones used in the client configuration.

.. code-block:: bash

    KEY_DEPLOYER=0x79ea8f62d97bc0591a4224c1725fca6b00de5b2cea286fe2e0bb35c5e76be46e
    KEY_ALICE=0x1af2e950272dd403de7a5760d41c6e44d92b6d02797e51810795ff03cc2cda4f
    KEY_BOB=0xf63d7d8e930bccd74e93cf5662fde2c28fd8be95edb70c73f1bdd863d07f412e
    BALANCE=10000000000000000000

    ganache-cli --host 127.0.0.1 --port 8545 --account $KEY_DEPLOYER,$BALANCE --account $KEY_ALICE,$BALANCE --account $KEY_BOB,$BALANCE --blockTime=5

The chain is running when you see an output like the following.

.. code-block:: none

    Ganache CLI v6.12.2 (ganache-core: 2.13.2)

    Available Accounts
    ==================
    (0) 0xe84d227431DfFcF14Fb8fa39818DFd4e864aeB13 (10 ETH)
    (1) 0x56FD289cEe714a5E471c418436EFA63E780D7a87 (10 ETH)
    (2) 0x6536425BE95A6661F6C6f68D709B6BE152785Df6 (10 ETH)

    Private Keys
    ==================
    (0) 0x79ea8f62d97bc0591a4224c1725fca6b00de5b2cea286fe2e0bb35c5e76be46e
    (1) 0x1af2e950272dd403de7a5760d41c6e44d92b6d02797e51810795ff03cc2cda4f
    (2) 0xf63d7d8e930bccd74e93cf5662fde2c28fd8be95edb70c73f1bdd863d07f412e

    Gas Limit
    ==================
    6721975

    Call Gas Limit
    ==================
    9007199254740991

    Listening on 127.0.0.1:8545


You can see Alice's and Bob's addresses starting with ``0x56F…`` and ``0x653…`` having both 10 ETH.
After we have run the example above, Alice and Bob are expected to have approximately 7 ETH and 13 ETH.
Depending on the ``--gasPrice`` set in the *ganache-cli*, numbers will not match exactly as some ETH are burned for performing the on-chain transactions.

Now run the tutorial application with:

.. code-block:: bash

    go run .


If everything works, you should see the following output.

.. code-block:: none

    2022/02/07 16:42:17 Deploying contracts.
    2022/02/07 16:42:25 Setting up clients.
    2022/02/07 16:42:25 Client balances (ETH): [10 10]
    2022/02/07 16:42:25 Opening channel and depositing funds.
    2022/02/07 16:42:30 Sending payments...
    2022/02/07 16:42:30 Settling channel.
    2022/02/07 16:42:34 Adjudicator event: type = *channel.ConcludedEvent, client = 0x6536425BE95A6661F6C6f68D709B6BE152785Df6
    2022/02/07 16:42:40 Adjudicator event: type = *channel.ConcludedEvent, client = 0x56FD289cEe714a5E471c418436EFA63E780D7a87
    2022/02/07 16:42:45 Client balances (ETH): [7 13]


With this, we conclude the Ethereum part of the payment channel tutorial.
Further, a description on how to migrate this implementation onto Polkadot is available :ref:`here <payment_client_on_polkadot>`.
