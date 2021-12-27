Configuration
=============
There are several ways to load the necessary configuration at startup.
For exemplary purposes, we will hard-code all parameters. You could also parse it from command
line flags or read a *json/yaml* file. The configuration parameters are highly dependent on the blockchain that you want to use *go-perun* with. Since this example only uses *Ethereum*, it only needs *Ethereum* parameters.

*Alice* and *Bob* both get a `Role` to define specific behavior.
This will be used to decide which side of the protocol to execute. We will put this in the `client` package, which will be explained later in this tutorial.

.. code-block:: go

    type Role int

    const (
        RoleAlice Role = 0
        RoleBob   Role = 1
    )

Let's move to the `main` package. We put all parameters in a `config` struct and create a global `cfg` variable that will
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

