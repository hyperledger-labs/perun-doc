Perun Client
============
The Perun Client combines multiple fundamental elements that will allow us to
talk with (and listen to) the channel and perform on-chain actions accordingly.
The Perun Client itself consists of two separate clients.
The channel interaction is performed via the State Channel Client (`stateChClient`)
and the interaction with the chain is performed by the Ethereum Client (`ethClient`).
Additionally the Perun Client includes the Bus, Listener, Contract Backend, Wallet and Account.
The following code is located in the client package / setup.go.
Note that this code can also be very useful for more complex channel types, like App Channels.

.. code-block:: go

    type PerunClient struct {
        Role            Role
        EthClient       *ethclient.Client
        StateChClient   *client.Client
        Bus             *net.Bus
        Listener        net.Listener
        ContractBackend channel.ContractInterface
        Wallet          *swallet.Wallet
        Account         *swallet.Account
    }

We will go through the components in the following and define some functions that will help us create the Perun Client in the end:

EthClient & Contract Backend
---------
For blockchain communication we need an `ethclient.Client` and a `channel.ContractBackend`.
The `ethclient` is the communicator on which the `ContractBackend` is built for go-perun to interact with the on-chain contracts.
The `ContractBackend` also includes a `channel.Transactor` that handles the generation of valid transactions.

You can create an `ethclient.Client` by calling `ethclient.Dial` with the URL of the node to connect.
The `ContractBackend` can then be created by providing the generated `ethClient` and the given `Transactor`.

.. code-block:: go

    func createContractBackend(nodeURL string, transactor channel.Transactor) (*ethclient.Client, channel.ContractBackend, error) {
        ethClient, err := ethclient.Dial(nodeURL)
        if err != nil {
            return nil, channel.ContractBackend{}, nil
        }

        return ethClient, channel.NewContractBackend(ethClient, transactor), nil
    }

StateChClient & Funder
-------------
The interactions with go-perun channels are executed by a `client.Client` object.
To prevent confusion with the clients of our scenario we call this client `stateChClient`.
Incoming interactions are realised via callbacks that trigger handling routines.
We describe the handlers in the next section.

In order to create the `stateChClient` go-perun provides `client.New()` that we utilize in the next section.
`client.New()` requires a `Funder`.

The `Funder` allows the participants to interact with the asset holder contract.
For easy creation we build `createFunder()`.
We start with creating a new Funder by calling `channel.NewFunder` giving the contract backend.
Then we cast the asset holder contract address to a perun address.
Next, we create the actual depositor `ETHDepositor` that will allow us to deposit ethereum funds.
Finally, the depositor and the client's account are registered for the specified asset inside the `Funder`.

.. code-block:: go

    func createFunder(cb channel.ContractBackend, account accounts.Account, assetHolder common.Address) *channel.Funder {
        f := channel.NewFunder(cb)
        asset := wallet.Address(assetHolder)
        depositor := new(channel.ETHDepositor)
        f.RegisterAsset(asset, depositor, account)
        return f
    }

Listener & Bus
-------------

The `Listener` allows participants to listen for incoming peer-to-peer connections.
The `Bus` is needed to initialize the perun client later on and forms the central message bus used as the transport layer abstraction of the channel network.
To build these two components we create `setupNetwork()`:

.. code-block:: go

    func setupNetwork(account wire.Account, host string, peerAddresses []PeerWithAddress, dialerTimeout time.Duration) (listener net.Listener, bus *net.Bus, err error) {
        dialer := simple.NewTCPDialer(dialerTimeout)

        for _, pa := range peerAddresses {
            dialer.Register(pa.Peer, pa.Address)
        }

        listener, err = simple.NewTCPListener(host)
        if err != nil {
            err = fmt.Errorf("creating listener: %w", err)
            return
        }

        bus = net.NewBus(account, dialer)
        return listener, bus, nil
    }



Perun Client generation
-----------------------
We bring everything together in one central `setupPerunClient()` functionality.
For easy transfer of the arguments we utilize a config struct:

.. code-block:: go

    type PerunClientConfig struct {
        Role            Role
        PrivateKey      *ecdsa.PrivateKey
        Host            string
        ETHNodeURL      string
        AdjudicatorAddr common.Address
        AssetHolderAddr common.Address
        DialerTimeout   time.Duration
        PeerAddresses   []PeerWithAddress
    }

Let us do this step-by-step.
    #. We use the `PrivateKey` to create the client's wallet and account with the simple wallet (`swallet`) provided by go-perun
    #. `swallet.NewTransactor()` will allow us to generate valid transactions with an account. We need a `signer` to specify how `transactor` will sign. We want to sign EIP155 transactions on our local chain, therefore, we create an `EIP155Signer` object with ganache's default chain id 1337. Then we call earlier described `createContractBackend()` with the `transactor` and `ETHNodeURL`. This generates the `ethClient` and the contract backend `cb`.
    #. Next, we want to generate the `adjudicator` responsible for judging, which means allowing to close the Payment Channel. We can use `channel.NewAdjudicator()` for this. It takes the contract backend `cb`, and the adjudicator contract address `AdjudicatorAddr` as arguments. Additionally, a receiver and sender address. The receiver is the on-chain address that receives the withdrawals, therefore for both the client's account address.
    #. Via `setupNetwork()`, we generate the earlier described `listener` and `bus`. Besides the account, it takes the `host`, `PeerAddresses` and `DialerTimeout` from the given `PerunClientConfig` as arguments. The `host` identifies the client on-chain. The `PeerAddresses` are necessary for peer-to-peer communication. The `DialerTimeout` is the maximum amount of time that is waited for a network connection (TCP dialer).
    #. Further, we create the `funder` by giving the contract backend, the account address and `AssetHolderAddr` to previously detailed `createFunder()`.
    #. Finally, we create `stateChClient`, our State Channel Client used as the central controller to interact with the state channel network, e.g., to propose channels to others.
We wrap the components inside the `PerunClient` struct and return them to conclude `setupPerunClient()`.

.. code-block:: go

    func setupPerunClient(cfg PerunClientConfig) (*PerunClient, error) {
        // Step 1: Create wallet and account
        clientWallet := swallet.NewWallet(cfg.PrivateKey)
        addr := wallet.AsWalletAddr(crypto.PubkeyToAddress(cfg.PrivateKey.PublicKey))
        pAccount, err := clientWallet.Unlock(addr)
        if err != nil {
            panic("failed to create account")
        }
        account := pAccount.(*swallet.Account)

        // Step 2: Create Ethereum client and contract backend
        signer := types.NewEIP155Signer(big.NewInt(1337))
        transactor := swallet.NewTransactor(clientWallet, signer)

        ethClient, cb, err := createContractBackend(cfg.ETHNodeURL, transactor)
        if err != nil {
            return nil, errors.WithMessage(err, "creating contract backend")
        }

        // Step 3: Adjudicator
        adjudicator := channel.NewAdjudicator(cb, cfg.AdjudicatorAddr, account.Account.Address, account.Account)

        // Step 4: listener & bus
        listener, bus, err := setupNetwork(account, cfg.Host, cfg.PeerAddresses, cfg.DialerTimeout)
        if err != nil {
            return nil, errors.WithMessage(err, "setting up network")
        }

        // Step 5: Funder
        funder := createFunder(cb, account.Account, cfg.AssetHolderAddr)


        // Step 6: State Channel Client
        stateChClient, err := client.New(account.Address(), bus, funder, adjudicator, clientWallet)
        if err != nil {
            return nil, errors.WithMessage(err, "creating client")
        }

        return &PerunClient{cfg.Role, ethClient, stateChClient, bus, listener, cb, clientWallet, account}, nil
    }
