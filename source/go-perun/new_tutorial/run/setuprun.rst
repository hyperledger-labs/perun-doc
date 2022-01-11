.. _setup-the-app:

Environment
=============
To prepare the execution environment for our specific example, we need to create a configuration.
We then create a method that allows us to instantiate a client for Alice and Bob based on this configuration.
We put the following code in main.go.

Configuration
-------------
There are several ways to load the necessary configurations at startup.
For exemplary purposes, we will hard-code all parameters. You could also parse it from command
line flags or read a json/yaml file. The configuration parameters are highly dependent on the blockchain that you want to use go-perun with. Since this example only uses Ethereum, it only needs Ethereum parameters.


We will do this in the `main` package (main.go). We put all parameters in a `config` struct and create a global `cfg` variable that will
hold the configuration.

.. code-block:: go

    type config struct {
        chainURL                string                            // Url of the Ethereum node.
        chainID                 *big.Int                          // ID of the targeted chain
        hosts                   map[client.Role]string            // Hosts for incoming connections.
        privateKeys             map[client.Role]*ecdsa.PrivateKey // Private keys.
        addrs                   map[client.Role]*wallet.Address   // Wallet addresses.
        defaultContextTimeout   time.Duration                     // Default time for timeout
    }

    var cfg config

Then we need an init function that will set all configuration fields on startup.
Most notably, we use the standard ganache URL + chainID and hard code the private keys of Alice and Bob, which we convert to ECDSA keys before we fix their on-chain addresses.

.. code-block:: go

    func initConfig() {
        cfg.chainURL = "ws://127.0.0.1:8545"
        cfg.chainID = big.NewInt(1337)
        cfg.hosts = map[client.Role]string{
            client.RoleAlice: "0.0.0.0:8400",
            client.RoleBob:   "0.0.0.0:8401",
        }

        cfg.defaultContextTimeout = 15 * time.Second

        // convert the private key strings ...
        rawKeys := []string{
            "1af2e950272dd403de7a5760d41c6e44d92b6d02797e51810795ff03cc2cda4f", // Alice
            "f63d7d8e930bccd74e93cf5662fde2c28fd8be95edb70c73f1bdd863d07f412e", // Bob
        }

        // ... to ECDSA keys:
        privateKeys := make(map[client.Role]*ecdsa.PrivateKey, len(rawKeys))
        for index, key := range rawKeys {
            privateKey, _ := crypto.HexToECDSA(key)
            privateKeys[client.Role(index)] = privateKey
        }
        cfg.privateKeys = privateKeys

        // Fix the on-chain addresses of Alice and Bob.
        addresses := make(map[client.Role]*wallet.Address, len(rawKeys))
        for index, key := range cfg.privateKeys {
            commonAddress := crypto.PubkeyToAddress(key.PublicKey)
            addresses[index] = wallet.AsWalletAddr(commonAddress)
        }
        cfg.addrs = addresses
    }

If you want to use different `rawKeys`, make sure to adapt the `ganache-cli` command accordingly.
Otherwise, there will be no funded accounts available for the payment channel.

Instantiate the clients
-----------------------------
Let us now combine everything we learned and set up two clients. One for Alice, one for Bob.

We create a helper function first that will wrap our general configuration and turn it into a `client.ClientConfig` (including it's `PerunClientConfig`) needed for `client.StartClient()` that we discussed earlier.
This will make our setup process much cleaner.

.. code-block:: go

    func createClientConfig(role client.Role, nodeURL string, contracts ContractAddresses, privateKey *ecdsa.PrivateKey, host string, peerAddress *wallet.Address, peerHost string) client.ClientConfig {
        return client.ClientConfig{
            PerunClientConfig: client.PerunClientConfig{
                Role:            role,
                PrivateKey:      privateKey,
                Host:            host,
                ETHNodeURL:      nodeURL,
                AdjudicatorAddr: contracts.AdjudicatorAddr,
                AssetHolderAddr: contracts.AssetHolderAddr,
                DialerTimeout:   1 * time.Second,
                PeerAddresses: []client.PeerWithAddress{
                    {
                        Peer:    peerAddress,
                        Address: peerHost,
                    },
                },
            },
            ContextTimeout: cfg.defaultContextTimeout,
        }
    }

Then we do the actual setup.
Let us go through it step-by-step.
All functions used here were described over the course of this tutorial.

#. Call initConfig to fill the general `config` struct. Notice that all relevant information is provided by `cfg` from here on.
#. Let Bob deploy the adjudicator and asset holder by calling `deployContracts()`. The addresses for both contracts are now available in `contracts`.
#. We create the `ClientConfig` for Alice by calling our helper function `createClientConfig()`. Have a look at the signature of `createClientConfig()` if you have trouble understanding the given arguments. Most notably 'peerAddress' and 'peerHost' (therefore 'cfg.addrs[client.RoleBob]' and 'cfg.hosts[client.RoleBob]') define the clients opponent here.
#. Then the client of Alice is started by calling `client.StartClient()` with the generated config.
#. Steps 3. & 4. are repeated for the client of Bob with the respective arguments.
#. Ultimately both clients are returned.

.. code-block:: go

    func setup() (*client.Client, *client.Client) {
        initConfig()

        // Deploy contracts (Bob deploys)
        fmt.Println("Deploying contracts...")
        nodeURL := cfg.chainURL
        contracts, err := deployContracts(nodeURL, cfg.chainID, cfg.privateKeys[client.RoleBob], cfg.defaultContextTimeout)
        if err != nil {
            panic(fmt.Errorf("deploying contracts: %v", err))
        }

        fmt.Println("Setting up clients...")
        // Setup Alice
        clientConfig1 := createClientConfig(
            client.RoleAlice, nodeURL, contracts,
            cfg.privateKeys[client.RoleAlice], cfg.hosts[client.RoleAlice],
            cfg.addrs[client.RoleBob], cfg.hosts[client.RoleBob],
        )

        c1, err := client.StartClient(clientConfig1)
        if err != nil {
            panic(fmt.Errorf("alice setup: %v", err))
        }

        // Setup Bob
        clientConfig2 := createClientConfig(
            client.RoleBob, nodeURL, contracts,
            cfg.privateKeys[client.RoleBob], cfg.hosts[client.RoleBob],
            cfg.addrs[client.RoleAlice], cfg.hosts[client.RoleAlice],
        )

        c2, err := client.StartClient(clientConfig2)

        if err != nil {
            panic(fmt.Errorf("bob setup: %v", err))
        }
        fmt.Println("Setup done.")

        return c1, c2
    }

.. toctree::
   :hidden: