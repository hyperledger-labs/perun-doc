Contracts
=========

go-perun uses two on-chain contracts: the Adjudicator and the Asset Holder.
They are written in the contract language of Ethereum; solidity.

Each contract must be deployed before go-perun can be used.
Usually, you would assume that they are already deployed and the addresses are known in advance.
But since this is a complete example for a local chain, we must deploy them.

Adjudicator
-----------

The Adjudicator contract ensures that a user can always enforce the rules of his channel.
Since the main part of the communication is off-chain, he would only contact the Adjudicator if he felt betrayed by one of the participants.

Asset Holder
-----------

The Asset Holder holds the on-chain balances for all ledger channels. It is always associated with a specific Adjudicator instance.

All participants deposit their funds into the Asset Holder before a channel can be opened.
All participants can withdraw their funds via the Asset Holder when the channel is closed.
In the case of a dispute, the Asset Holder respects the decision of its Adjudicator on how to proceed.

go-perun uses one contract per asset on top of the Ethereum blockchain.
In this example, we only use the `ETHAssetHolder`, which is used for ether, the native
currency in Ethereum.
ERC20 Tokens are supported via the `ERC20AssetHolder`.

Deployment
----------

Deploying a contract means installing it on the blockchain. A deployed contract has a fixed public address.
We will deploy both contracts as a demonstration. In a running go-perun ecosystem, the contracts' addresses would be known in advance, and you would just verify them.

In the `main` package, we define the `deployContracts` function in util.go.
We use the `ethContractClient` object here.
It will be explained on a low level in the Contract Deployment section but using it here as a black box in mind is relatively straightforward.

First, we create an `ethContractClient` that allows us to communicate the contract deployment to the chain.
The `deploymentKey` is the ECDSA key of the party deploying the contracts, therefore either Alice or Bob.
The `contextTimeout` is needed to specify how long `go-perun` will wait for both deployments to succeed.

We then deploy the Adjudicator with `DeployAdjudicator()`.
We use the Adjudicator's address to deploy the AssetHolder with `DeployAssetHolderETH()`.
Note that if you have set a higher block time in `ganache`, you need to increase the timeout here too.

Next, we wait for the deployment by calling `WaitDeployment()`.
If the contracts were deployed successfully, we return both contract addresses bundled as `ContractAddresses`.

.. code-block:: go

    func deployContracts(nodeURL string, chainID *big.Int, deploymentKey *ecdsa.PrivateKey, contextTimeout time.Duration) (contracts ContractAddresses, err error) {
        ethContractClient, err := eth.NewEthContractClient(nodeURL, deploymentKey, chainID, contextTimeout)
        if err != nil {
            err = errors.WithMessage(err, "creating ethereum client")
            return
        }

        // Deploy adjudicator
        adjudicatorAddr, txAdj, err := ethContractClient.DeployAdjudicator()
        if err != nil {
            err = errors.WithMessage(err, "deploying adjudicator")
            return
        }

        // Deploy asset holder
        assetHolderAddr, txAss, err := ethContractClient.DeployAssetHolderETH(adjudicatorAddr)
        if err != nil {
            err = errors.WithMessage(err, "deploying AssetHolderETH")
            return
        }

        err = ethContractClient.WaitDeployment(txAdj, txAss)
        if err != nil {
            err = errors.WithMessage(err, "waiting for contract deployment")
            return
        }

        return ContractAddresses{
            AdjudicatorAddr: adjudicatorAddr,
            AssetHolderAddr: assetHolderAddr,
        }, nil
    }

    type ContractAddresses struct {
        AdjudicatorAddr, AssetHolderAddr common.Address
    }

Verification (note)
----------

.. warning::
   When communicating with outside parties, you should always verify a contract before using it to ensure that you don't lose funds. In our example, we create all contracts. Therefore, we can trust them.

Functions like `ValidateAssetHolderETH`_ help you with verifying contracts. It could look something like this:

.. code-block:: go

    func validateContracts(cb ethchannel.ContractBackend, adj, ah common.Address) error {
        ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
        defer cancel()
        return ethchannel.ValidateAssetHolderETH(ctx, cb, ah, adj)
    }

Note that the AssetHolder validation function also implicitly validates the linked Adjudicator.

.. _ValidateAssetHolderETH: https://pkg.go.dev/perun.network/go-perun/backend/ethereum/channel#ValidateAssetHolderETH
.. _dispute: ../channels/disputes.html
