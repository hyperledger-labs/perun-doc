Execute
=======

Finally, we want to use our preliminary work to perform a test run by instantiating the clients and performing a simple payment over a channel.
Ultimately you can run main.go to see the individual steps executing in your command line output.

main() method
-------------
We create the client for Alice and Bob by calling `setup()` and let Bob open a new channel by calling `client.OpenChannel()` with Alice's role as the `peer` argument.
As we defined earlier, this creates a payment channel with both participants depositing 10 ETH each.
Next we let Bob call `client.UpdateChannel()` to transfer 5 ETH to Alice.
Finally, Bob closes the channel by calling `client.CloseChannel()`.
Alice and Bob pick up their assets according to the settled channel.
Therefore, (not including gas fees) Bob receives 5 ETH, and Alice receives 15 ETH.

.. code-block:: go

    func main() {
        alice, bob := setup()
        logAccountBalance(alice, bob)

        if err := bob.OpenChannel(cfg.addrs[client.RoleAlice]); err != nil {
            panic(fmt.Errorf("opening channel: %w", err))
        }
        if err := bob.UpdateChannel(); err != nil {
            panic(fmt.Errorf("updating channel: %w", err))
        }
        if err := bob.CloseChannel(); err != nil {
            panic(fmt.Errorf("closing channel: %w", err))
        }

        logAccountBalance(alice, bob)
    }

.. _run-the-app:

Run our example from the command line
-------------------------------------
First, we need to start our local Ethereum blockchain with the `ganache-cli`.
We do this in the command line.
Notice that the chain URL, the port, and both private keys are also found in the `initConfig()` function defined before::

    ganache-cli --host 127.0.0.1 --port 8545 --account 0x1af2e950272dd403de7a5760d41c6e44d92b6d02797e51810795ff03cc2cda4f,100000000000000000000 --account 0xf63d7d8e930bccd74e93cf5662fde2c28fd8be95edb70c73f1bdd863d07f412e,100000000000000000000 --blockTime=1

The chain is running when you see an output like this:

.. code-block:: console

   Ganache CLI v6.12.2 (ganache-core: 2.13.2)

    Available Accounts
    ==================
    (0) 0x56FD289cEe714a5E471c418436EFA63E780D7a87 (100 ETH)
    (1) 0x6536425BE95A6661F6C6f68D709B6BE152785Df6 (100 ETH)

    Private Keys
    ==================
    (0) 0x1af2e950272dd403de7a5760d41c6e44d92b6d02797e51810795ff03cc2cda4f
    (1) 0xf63d7d8e930bccd74e93cf5662fde2c28fd8be95edb70c73f1bdd863d07f412e

    Gas Price
    ==================
    20000000000

    Gas Limit
    ==================
    6721975

    Call Gas Limit
    ==================
    9007199254740991

    Listening on 127.0.0.1:8545


You can see Alice's and Bob's addresses starting with `0x56F…` and `0x653…` having both 100 *ETH*.

Now run the tutorial application via the following command::

    go run .


If everything works, you should see the following output.

.. code-block:: console

    Deploying contracts...
    Setting up clients...
    Setup done.
    2022/01/11 10:55:31 Alice with address 0x56FD289cEe714a5E471c418436EFA63E780D7a87 - Account Balance: 100ETH
    2022/01/11 10:55:31 Bob with address 0x6536425BE95A6661F6C6f68D709B6BE152785Df6 - Account Balance: 99.9291396ETH
    Bob: Opening channel from Bob to Alice
    Alice: Received channel proposal

     🎉 Opened channel with id 0x7e8124e0149182fd6a245b86b5f82209ef9661f763b2cb9544965e922153aca4

    Bob: Update channel by sending 5 ETH to Alice
    Alice: Accepted channel with id 0x7e8124e0149182fd6a245b86b5f82209ef9661f763b2cb9544965e922153aca4
    Alice: HandleNewChannel with id 0x7e8124e0149182fd6a245b86b5f82209ef9661f763b2cb9544965e922153aca4
    Alice: HandleUpdate
    Bob: Close Channel
    Alice: HandleAdjudicatorEvent
    Alice: Close Channel
    2022/01/11 10:55:35 Alice with address 0x56FD289cEe714a5E471c418436EFA63E780D7a87 - Account Balance: 104.99845458ETH
    2022/01/11 10:55:35 Bob with address 0x6536425BE95A6661F6C6f68D709B6BE152785Df6 - Account Balance: 94.92475986ETH



.. warning::
   | Running the code twice will not work without restarting the chain!
   | Always restart the chain if you need a deterministic testing environment.


The `ganache-cli` window will output the two deploy transactions.
The first for ~2M gas is the `Adjudicator`

.. code-block:: console

    Transaction: 0x28a3d1b70f276ca84cb423e5356aabee4b0bdc83f2d205ecdd3a303c72be705f
    Contract created: 0xf9a290cb1b95e0dbda4904f4ab33f9568a7f2f3f
    Gas usage: 2675281
    Block Number: 431
    Block Time: Tue Jan 11 2022 11:35:26 GMT+0100 (Mitteleuropäische Normalzeit)

and then the `AssetHolder` for ~870K gas

.. code-block:: console

    Transaction: 0x12c4639e682c65ebfe14085eff2c53bc89e65fc3e066bf0b12c3f12870924196
    Contract created: 0x2f0fd01ba39b0581da0f42f86b23ade80db623a0
    Gas usage: 867739
    Block Number: 431
    Block Time: Tue Jan 11 2022 11:35:26 GMT+0100 (Mitteleuropäische Normalzeit)


The following two transactions are the funding calls on the `AssetHolder`:

.. code-block:: console

    Transaction: 0x685c83facc1d612a3c1c1ed5512d577e8f40ed85552bd2cd5ab7f6bb2fbc7ea6
    Gas usage: 44560
    Block Number: 432
    Block Time: Tue Jan 11 2022 11:35:27 GMT+0100 (Mitteleuropäische Normalzeit)


    Transaction: 0x18a249d640c17c8cc17a8b9a201c42b4ed0bda3d87233a16789c9444558ce5d8
    Gas usage: 44560
    Block Number: 432
    Block Time: Tue Jan 11 2022 11:35:27 GMT+0100 (Mitteleuropäische Normalzeit)

Next is the `concludeFinal` call on the `Adjudicator`. It uses more gas than a normal transaction since it executes the conclusion logic.

.. code-block:: console

    Transaction: 0x7983c405d29bd353dd1e3475352b34e8e632b0ab6da77f0487cb4e1fa0cc1e07
    Gas usage: 141740
    Block Number: 433
    Block Time: Tue Jan 11 2022 11:35:28 GMT+0100 (Mitteleuropäische Normalzeit)

Finally, both participants withdraw their funds:

.. code-block:: console

    Transaction: 0xe626bf5c18e41ebe50aa0e803d0c7b786f9ec2cdb9c6903aef4d1f5362cced41
    Gas usage: 32731
    Block Number: 434
    Block Time: Tue Jan 11 2022 11:35:29 GMT+0100 (Mitteleuropäische Normalzeit)


    Transaction: 0xa7b98399401805a9ec5319109eea50206a45aec9415d9a9538073db32f603766
    Gas usage: 32731
    Block Number: 434
    Block Time: Tue Jan 11 2022 11:35:29 GMT+0100 (Mitteleuropäische Normalzeit)


.. toctree::
   :hidden: