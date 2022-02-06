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

.. code-block:: go

    // deployContracts deploys the Perun smart contracts on the specified ledger.
    func deployContracts(nodeURL string, chainID uint64, privateKey string) (adj, ah common.Address) {
        k, err := crypto.HexToECDSA(privateKey)
        if err != nil {
            panic(err)
        }
        w := swallet.NewWallet(k)
        cb, err := client.CreateContractBackend(nodeURL, chainID, w)
        if err != nil {
            panic(err)
        }
        acc := accounts.Account{Address: crypto.PubkeyToAddress(k.PublicKey)}


Using the Contract Backend `cb`, we then deploy the Adjudicator and Ethereum AssetHolder via go-perun's `ethchannel.DeployAdjudicator()` and `ethchannel.DeployETHAssetholder()`.
Note that the Adjudicator must be deployed first for using its address to make the AssetHolder depend on it.
Ultimately we return both addresses.

.. code-block:: go

        // Deploy adjudicator.
        adj, err = ethchannel.DeployAdjudicator(context.TODO(), cb, acc) //TODO:go-perun accept ethwallet Account instead?
        if err != nil {
            panic(err)
        }

        // Deploy asset holder.
        ah, err = ethchannel.DeployETHAssetholder(context.TODO(), cb, adj, acc) //TODO:go-perun accept ethwallet Account instead?
        if err != nil {
            panic(err)
        }

        return adj, ah
    }

Nice-To-Haves
=============
The following functions will help us generate or scenario in a neat way.

Client setup from secret key
------------------------------------

We want to start up a new client by simply giving his private key.
Therefore, we create a wrapper that parses a given private key into a go-ethereum simple wallet, like we already did in the contract deployment.
This wallet `w` is then used with the other required arguments to call `client.SetupPaymentClient` for generating a new `PaymentClient`

.. code-block:: go

    // setupPaymentClient sets up a new client with the given parameters.
    func setupPaymentClient(
        bus wire.Bus,
        nodeURL string,
        adjudicator common.Address,
        asset ethwallet.Address,
        privateKey string,
    ) *client.PaymentClient {
        // Create wallet and account.
        k, err := crypto.HexToECDSA(privateKey)
        if err != nil {
            panic(err)
        }
        w := swallet.NewWallet(k)
        acc := crypto.PubkeyToAddress(k.PublicKey)

        // Create and start client.
        c, err := client.SetupPaymentClient(
            bus,
            w,
            acc,
            nodeURL,
            chainID,
            adjudicator,
            asset,
        )
        if err != nil {
            panic(err)
        }

        return c
    }

Logging Balances
----------------
For a straightforward evaluation of our payment channel runs, printing the client's balance into the console output is handy.
To realize this, we create a new `balanceLogger` simply wrapping an `ethclient.Client` `ethClient` for reading accounts on the blockchain.

.. code-block:: go

    // balanceLogger is a utility for logging client balances.
    type balanceLogger struct {
        ethClient *ethclient.Client
    }

The constructor only requires the `chainURL` to dial the `ethClient` in.

.. code-block:: go

    // newBalanceLogger creates a new balance logger for the specified ledger.
    func newBalanceLogger(chainURL string) balanceLogger {
        c, err := ethclient.Dial(chainURL)
        if err != nil {
            panic(err)
        }
        return balanceLogger{ethClient: c}
    }

Finally, we implement the logging of balances with `LogBalances()` that takes an arbitrary amount of `PaymentClient`s to be logged.
For each client, the balance is fetched via go-ethereum's `ethclient.Client.BalanceAt()`.

.. code-block:: go

    // LogBalances prints the balances of the specified clients.
    func (l balanceLogger) LogBalances(clients ...*client.PaymentClient) {
        bals := make([]*big.Int, len(clients))
        for i, c := range clients {
            bal, err := l.ethClient.BalanceAt(context.TODO(), c.AccountAddress(), nil)
            if err != nil {
                log.Fatal(err)
            }
            bals[i] = bal
        }
        log.Println("Client balances:", bals)
    }


.. toctree::
   :hidden:
