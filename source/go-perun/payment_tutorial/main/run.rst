Execute
=======

Finally, we want to use our preliminary work to perform a test run by instantiating the clients and performing a simple payment over a channel.
We put the code of this section into `main.go`
Ultimately, you can run main.go to see the individual steps executing in your command line output.

Implementation
--------------
We implement our scenario by first setting all necessary constants and then using the previously built tools to make exemplary payments in `main()`.

Environment
...........

As we mentioned earlier, we need the `chainURL` and `chainID` to identify the blockchain we want to work with.
In this case, we use the standard `ganache-cli` values.
Additionally, we require three private keys.
On the one hand, a party that is deploying the contracts.
On the other hand, Alice and Bob that want to use our payment channel.

.. code-block:: go

    const (
        chainURL = "ws://127.0.0.1:8545"
        chainID  = 1337

        // Private keys.
        keyDeployer = "79ea8f62d97bc0591a4224c1725fca6b00de5b2cea286fe2e0bb35c5e76be46e"
        keyAlice    = "1af2e950272dd403de7a5760d41c6e44d92b6d02797e51810795ff03cc2cda4f"
        keyBob      = "f63d7d8e930bccd74e93cf5662fde2c28fd8be95edb70c73f1bdd863d07f412e"
    )

Scenario
........
We want to execute some payments between Alice and Bob in our scenario using the payment channel.
Note, that for simplicity, all balances are interpreted as the smallest possible Ethereum unit (Wei, 1 Wei = 0.000000000000000001 ETH).

#. We start with the deployment of the contracts by calling deployContracts() with the corresponding arguments. This supplies us with the `adjudicator` and `assetHolder` addresses.
#. Next we create a new message bus via `wire.NewLocalBus()`, which will be used by the clients to communicate with each other. Then we call the `setupPaymentClient()` functionality for both Alice and Bob.
#. Then the balance logger is initialized via `newBalanceLogger()` and `LogBalances()` prints the initial balance of both clients.
#. Further, Alice opens a channel with `OpenChannel()` with her peer `bob` and the initial funds she wants to put into this channel. Bob fetches this new channel from his registry by calling `AcceptedChannel()`.
#. Now everything is set up, and we let Alice and Bob exchange a few Wei back and forth.
#. We print the balances and let Alice settle to conclude and withdraw her funds from the channel. Bob also settles to withdraw his funds directly.
#. Finally, both clients shut down to free up the used resources.

.. code-block:: go

    // main runs a demo of the payment client. It assumes that a blockchain node is
    // available at `chainURL` and that the accounts corresponding to the specified
    // secret keys are provided with sufficient funds.
    func main() {
        // Deploy contracts.
        log.Println("Deploying contracts.")
        adjudicator, assetHolder := deployContracts(chainURL, chainID, keyDeployer)
        asset := ethwallet.AsWalletAddr(assetHolder)

        // Setup clients.
        log.Println("Setting up clients.")
        bus := wire.NewLocalBus() // Message bus used for off-chain communication. //TODO:tutorial Extension that explains tcp/ip bus.
        alice := setupPaymentClient(bus, chainURL, adjudicator, *asset, keyAlice)
        bob := setupPaymentClient(bus, chainURL, adjudicator, *asset, keyBob)

        // Print balances before transactions.
        l := newBalanceLogger(chainURL)
        l.LogBalances(alice, bob)

        // Open channel, transact, close.
        log.Println("Opening channel.")
        chAlice := alice.OpenChannel(bob, 10)
        chBob := bob.AcceptedChannel()

        log.Println("Sending payments.")
        chAlice.SendPayment(1)
        chBob.SendPayment(2)
        chAlice.SendPayment(3)

        log.Println("Settling channel.")
        chAlice.Settle() // Conclude and withdraw.
        chBob.Settle()   // Withdraw.

        // Print balances after transactions.
        l.LogBalances(alice, bob)

        // Cleanup.
        alice.Shutdown()
        bob.Shutdown()
    }

.. _run-the-app:

Run our example from the command line
-------------------------------------
First, we need to start our local Ethereum blockchain using the `ganache-cli`.
We do this in the command line.
Make sure the constants used above match the values used for the `ganache-cli` command::

    KEY_DEPLOYER=0x79ea8f62d97bc0591a4224c1725fca6b00de5b2cea286fe2e0bb35c5e76be46e
    KEY_ALICE=0x1af2e950272dd403de7a5760d41c6e44d92b6d02797e51810795ff03cc2cda4f
    KEY_BOB=0xf63d7d8e930bccd74e93cf5662fde2c28fd8be95edb70c73f1bdd863d07f412e
    BALANCE=100

    ganache-cli --host 127.0.0.1 --port 8545 --account $KEY_DEPLOYER,$BALANCE --account $KEY_ALICE,$BALANCE --account $KEY_BOB,$BALANCE --blockTime=5 --gasPrice=0

The chain is running when you see an output like this:

.. code-block:: console

   Ganache CLI v6.12.2 (ganache-core: 2.13.2)

    Available Accounts
    ==================
    (0) 0xe84d227431DfFcF14Fb8fa39818DFd4e864aeB13 (~0 ETH)
    (1) 0x56FD289cEe714a5E471c418436EFA63E780D7a87 (~0 ETH)
    (2) 0x6536425BE95A6661F6C6f68D709B6BE152785Df6 (~0 ETH)

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


You can see Alice's and Bob's addresses starting with `0x56F…` and `0x653…` having both ~0 *ETH*.
No worries, their accounts are funded; the values are just very small.
Our `balanceLogger` will print all decimals.

Now run the tutorial application with::

    go run .


If everything works, you should see the following output.

.. code-block:: console

    2022/01/31 17:42:02 Deploying contracts.
    2022/01/31 17:42:10 Setting up clients.
    2022/01/31 17:42:10 Client balances: [100 100]
    2022/01/31 17:42:10 Opening channel.
    2022/01/31 17:42:15 Sending payments.
    2022/01/31 17:42:15 Settling channel.
    2022/01/31 17:42:20 Adjudicator event: type = *channel.ConcludedEvent, client = 0x6536425BE95A6661F6C6f68D709B6BE152785Df6
    2022/01/31 17:42:25 Adjudicator event: type = *channel.ConcludedEvent, client = 0x56FD289cEe714a5E471c418436EFA63E780D7a87
    2022/01/31 17:42:30 Client balances: [94 106]

With this, we conclude our payment channel tutorial.

.. toctree::
   :hidden:
