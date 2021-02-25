Contracts
=========

*go-perun* uses two contracts: the *Adjudicator* and the *Assetholder*.
They are written in the contract language of Ethereum; *solidity*.
Each contract must be deployed before *go-perun* can be used.
Normally you would assume that they are already deployed and the addresses are known
in advance. But since this is a complete
example for a local chain, we must deploy them.

Adjudicator
-----------

The `Adjudicator` contract ensures that a user can always enforce the rules of his channel.
Since the main part of the communication is off-chain, he would only contact the `Adjudicator` if he feels betrayed by one of the participants.

AssetHolder
-----------

The `AssetHolder` holds the on-chain balances for all ledger channels. It is always associated with a specific `Adjudicator` instance.

All participants deposit their funds into the `AssetHolder` before a channel can be opened.
When the channel is closed all participants can withdraw their funds via the `AssetHolder`.
In the case of a dispute, the `AssetHolder` respects the decision of its `Adjudicator` on how to proceed.

*go-perun* uses one contract per asset on top of the *Ethereum* blockchain.
In this example we only use the *ETHAssetHolder* which is used for *ether*, the native
currency in *Ethereum*.
*ERC20 Tokens* are supported via the *ERC20AssetHolder*.

Deployment
----------

Deploying a contract means *installing* it on the blockchain. A deployed contract has a fixed public address.
We will deploy both contracts as demonstration. In a running *go-perun* ecosystem the contracts' *addresses* would be known in advance and you would just verify them.

First we have to deploy the *Adjudicator* and then use the *Adjudicator's* address to deploy the *AssetHolder*:

.. literalinclude:: ../go-perun-test/onchain.go
   :language: go
   :lines: 28-40

The context is needed to specify how long *go-perun* will wait for both deployments to succeed.
If you have set a higher block time in *ganache*, you need to increase the timeout here too.

.. note::

   *ganache-cli* shows deployments as a :code:`Contract created` transaction.

Validation
----------

*go-perun* can verify the addresses of deployed contracts.
There are verification methods for the *Adjudicator* and *AssetHolderETH*.
In our example, it is enough to use `ValidateAssetHolderETH`_ since the *AssetHolder* validation function also implicitly validates the linked *Adjudicator*.

.. warning::
   You should always verify a contract before using it to ensure that you don't lose funds.

We wrap it in a function that accepts a *ContractBackend* and the addresses of the *Adjudicator* and *Assetholder*.

.. literalinclude:: ../go-perun-test/onchain.go
   :language: go
   :lines: 42-47

Putting it together
-------------------

Since we have two roles, we need to combine the two functions and switch on the role that
is running:

.. literalinclude:: ../go-perun-test/onchain.go
   :language: go
   :lines: 49-65

The addresses for `Adjudicator` and `AssetHolder` can be hard-coded again since we know
what they will be when we deploy the contracts for the first time. This implies that
we always restart the *ganache-cli* before running it.

.. _ValidateAssetHolderETH: https://pkg.go.dev/perun.network/go-perun/backend/ethereum/channel#ValidateAssetHolderETH
.. _dispute: ../channels/disputes.html
