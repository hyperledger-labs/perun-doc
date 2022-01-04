Contract Deployment
============

We already mentioned that the Perun Client includes an Ethereum Client utilized for the participants communicating with the blockchain.
In this part, we use another instance of an Ethereum Client to realize deploying the Adjudicator and Asset Holder.
The contract deployment is realized separately from the Perun Client because it allows an external party (only given by its private key) to execute the deployment independently.

Setup
------
We bundle our `ethClient` together with other for the contract deploying relevant data in `EthContractClient`.
The `key` represents the deploying party's private key that is also required to pay the deployment gas fees.
The `chainID` indicates which chain we are deploying the contracts on, and `contextTimeout` defines the time we are willing to wait for the deployment confirmation.
`nonce` sets the initial value for the transaction nonce.

.. code-block:: go

    type EthContractClient struct {
        ethClient      *ethclient.Client
        key            *ecdsa.PrivateKey
        chainID        *big.Int
        contextTimeout time.Duration
        nonce          int64
    }

Then we create `NewEthContractClient()` to initialize our `EthContractClient`.
Mainly the `ethClient` is initialized here. We do this by calling `ethclient.Dial` with the `nodeURL`.

.. code-block:: go

    func NewEthContractClient(nodeURL string, key *ecdsa.PrivateKey, chainID *big.Int, contextTimeout time.Duration) (*EthContractClient, error) {
        ctx, cancel := context.WithTimeout(context.Background(), contextTimeout)
        defer cancel()
        client, err := ethclient.DialContext(ctx, nodeURL)
        if err != nil {
            return nil, err
        }
        return &EthContractClient{client, key, chainID, contextTimeout, 0}, nil
    }


Custom Transactor
~~~~~~~~~~
For creating the ethereum transactions, we need transactors again.
We cannot use (the previously presented) `newTransactor()` method that comes with the simple wallet because we are only dealing with a single private key here.
To avoid creating the whole instance of a wallet, we make our own custom `newTransactor()` method.

We use `bind.NewKeyedTransactorWithChainID()` from the go-ethereum library to easily create a new transactor from only our `key` and the `chainID`.
For each deployment, we will need to use a separate transactor. Each is required to have its own `nonce`.
Therefore we set the transactor's nonce and increment it afterward to have an unused one available for the next call.

.. code-block:: go

    func (c *EthContractClient) newTransactor(ctx context.Context) (*bind.TransactOpts, error) {
        tr, err := bind.NewKeyedTransactorWithChainID(c.key, c.chainID)
        if err != nil {
            return nil, err
        }
        tr.Context = ctx
        tr.Nonce = big.NewInt(c.nonce)
        c.nonce++
        return tr, nil
    }

Deployment
------

We start with the actual deployment by defining a general method that we can use for both contract types.

General Deployment
~~~~~~~~~~

`deployContracts()` gets a function `deployContract` specific to the contract and a bool `waitConfirmation` as arguments.
We create a new transactor by calling our custom `newTransactor()` method.
Next, we call the given function with the transactor and our Ethereum Client.
This ultimately sends the deployment transaction to the blockchain, as you will see in a moment.
If `waitConfirmation` is set to true, we wait for the deployment transaction to be mined before returning the on-chain contract's address and the transaction itself.

.. code-block:: go

    func (c *EthContractClient) deployContract(
        deployContract func(*bind.TransactOpts, *ethclient.Client) (common.Address, *types.Transaction, error),
        waitConfirmation bool,
    ) (common.Address, *types.Transaction, error) {

        ctx, cancel := c.defaultContext()
        defer cancel()
        ethClient := c.ethClient
        tr, err := c.newTransactor(ctx)

        if err != nil {
            return common.Address{}, nil, err
        }

        addr, tx, err := deployContract(tr, ethClient)
        if err != nil {
            return common.Address{}, nil, errors.WithMessage(err, "sending deployment transaction")
        }

        if waitConfirmation {
            addr, err = bind.WaitDeployed(ctx, ethClient, tx)
            if err != nil {
                return common.Address{}, nil, errors.WithMessage(err, "waiting for the deployment transaction to be mined")
            }
        }
        return addr, tx, nil
    }

Deploy Adjudicator & Asset Holder
~~~~~~~~~~
Deploying the actual contract type is now straightforward.
We call `deployContact()` with either `adjudicator.DeployAdjudicator()` or `assetholdereth.DeployAssetHolderETH()` including the transactor and `ethClient`.
Note that only the asset holder needs the address of the adjudicator as an argument.
This is because the adjudicator is created first, and the asset holder is dependent on it.

.. code-block:: go

    func (c *EthContractClient) DeployAdjudicator() (addr common.Address, tx *types.Transaction, err error) {
        return c.deployContract(func(to *bind.TransactOpts, c *ethclient.Client) (addr common.Address, tx *types.Transaction, err error) {
            addr, tx, _, err = adjudicator.DeployAdjudicator(to, c)
            return
        }, false)
    }

    func (c *EthContractClient) DeployAssetHolderETH(adjudicatorAddr common.Address) (addr common.Address, tx *types.Transaction, err error) {
        return c.deployContract(func(to *bind.TransactOpts, c *ethclient.Client) (addr common.Address, tx *types.Transaction, err error) {
            addr, tx, _, err = assetholdereth.DeployAssetHolderETH(to, c, adjudicatorAddr)
            return
        }, false)
    }
