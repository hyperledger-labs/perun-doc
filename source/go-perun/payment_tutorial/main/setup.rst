.. _setupscenario:

Setup Scenario
##############
Before creating our exemplary scenario, we construct a few helper functions that will cover the contract deployment, client generation, and logging of balances in the command line.
We put the code of this section into `util.go`

Deploy Contracts
================

go-perun uses two on-chain contracts: the Adjudicator and the Asset Holder.
They are written in the contract language of Ethereum, `Solidity <https://docs.soliditylang.org/en/latest/>`__, and are part of go-perun's Ethereum backend.

Each contract must be deployed before go-perun can be used.
Usually, you would assume that they are already deployed, and the addresses are known in advance.
But since this is a complete example for a local chain, we must deploy them.

Concept: Adjudicator  & Asset Holder
------------------------------------
The Adjudicator contract ensures that a user can consistently enforce the rules of his channel.
Since the central part of the communication is off-chain, he would only contact the Adjudicator if he felt betrayed by the participants or for concluding the channel.

The Asset Holder holds the on-chain balances for all ledger channels. It is always associated with a specific Adjudicator instance.

All participants deposit their funds into the Asset Holder before a channel can be opened.
All participants can withdraw their funds via the Asset Holder when the channel is closed.
In the case of a dispute, the Asset Holder respects the decision of its Adjudicator on how to proceed.

go-perun uses one contract per asset on top of the Ethereum blockchain.
In this example, we only use the `ETHAssetHolder`, which is used for Ether, the native currency in Ethereum.
ERC20 Tokens are supported via the `ERC20AssetHolder`.

Implementation
--------------

Go-perun makes the deployment of the standard Adjudicator and Ethereum AssetHolder easy.
As stated before: In a running go-perun ecosystem, the contracts' addresses would be known in advance, and you would verify them.
In our example, we will deploy contracts ourselves at the start of the program:

Let us define `deployContracts()` with the `nodeURL`, `chainID` and the `privateKey` of the deployer as arguments.

First, we create an instance of go-perun's simple wallet by calling `swallet.NewWallet()`.
With this wallet `w`, the `nodeURL`, and `chainID`, we can reuse our client's utility function `CreateContractBackend()` to sign and send our deployment transactions.

.. literalinclude:: ../../../perun-examples/payment-channel/util.go
   :language: go
   :lines: 33-44


Using the contract backend `cb`, we then deploy the Adjudicator and Ethereum AssetHolder via go-perun's `ethchannel.DeployAdjudicator()` and `ethchannel.DeployETHAssetholder()`.
Note that the Adjudicator must be deployed first for using its address to make the AssetHolder depend on it.
Ultimately we return both addresses.

.. literalinclude:: ../../../perun-examples/payment-channel/util.go
   :language: go
   :lines: 46-59

Nice-To-Haves
=============
The following functions will help us generate or scenario in a neat way.

Client setup from secret key
------------------------------------

We want to start up a new client by simply giving his private key.
Therefore, we create a wrapper that parses a given private key into a go-ethereum simple wallet, like we already did in the contract deployment.
This wallet `w` is then used with the other required arguments to call `client.SetupPaymentClient` for generating a new `PaymentClient`

.. literalinclude:: ../../../perun-examples/payment-channel/util.go
   :language: go
   :lines: 61-92

Logging Balances
----------------
For a straightforward evaluation of our payment channel runs, printing the client's balance into the console output is handy.
To realize this, we create a new `balanceLogger` simply wrapping an `ethclient.Client` `ethClient` for reading accounts on the blockchain.

.. literalinclude:: ../../../perun-examples/payment-channel/util.go
   :language: go
   :lines: 94-97

The constructor only requires the `chainURL` to dial the `ethClient` in.

.. literalinclude:: ../../../perun-examples/payment-channel/util.go
   :language: go
   :lines: 99-106

Finally, we implement the logging of balances with `LogBalances()` that takes an arbitrary amount of `PaymentClient`s to be logged.
For each client, the balance is fetched via go-ethereum's `ethclient.Client.BalanceAt()`.

.. literalinclude:: ../../../perun-examples/payment-channel/util.go
   :language: go
   :lines: 108-119


.. toctree::
   :hidden:
