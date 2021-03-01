Putting it together
===================

Now we combine all the components that we previously setup in a *setup* function.
It will be called once for *Alice* and once for *Bob* from *main* like this:

.. literalinclude:: ../../perun-examples/simple-client/main.go
   :language: go
   :lines: 14-34

.. literalinclude:: ../../perun-examples/simple-client/main.go
   :language: go
   :lines: 35-

.. _run-the-app:

Running the App
---------------

Now we can finally test if everything works together.

First start your local Ethereum blockchain specifying the block time, the number of accounts, and the mnemonic::

   ganache-cli -b 5 -a 2 -m "pistol kiwi shrug future ozone ostrich match remove crucial oblige cream critic"

The chain is running when you see an output like this:

.. code-block:: console

   Ganache CLI v6.12.1 (ganache-core: 2.13.1)

   Available Accounts
   ==================
   (0) 0x2EE1ac154435f542ECEc55C5b0367650d8A5343B (100 ETH)
   (1) 0x70765701b79a4e973dAbb4b30A72f5a845f22F9E (100 ETH)
   
   Private Keys
   ==================
   (0) 0xb691bc22c5a30f64876c6136553023d522dcdf0744306dccf4f034a465532e27
   (1) 0xb5dc82fc5f4d82b59a38ac963a15eaaedf414f496a037bb4a52310915ac84097
   
   HD Wallet
   ==================
   Mnemonic:      pistol kiwi shrug future ozone ostrich match remove crucial oblige cream critic
   Base HD Path:  m/44'/60'/0'/0/{account_index}
   
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


You can see *Alice'* and *Bobs* addresses starting with `0x2EE…` and `0x707…` having both 100 *ETH*.

Now run the tutorial application via the following command::

   go run .

If everything works, you should see the following output::

   Starting  Alice
   Deployed contracts
    Adjudicator at 0x079557d7549d7D44F4b00b51d2C532674129ed51
    AssetHolder at 0x923439be515b6A928cB9650d70000a9044e49E85
   Setting up listener for 0.0.0.0:8401
   Starting  Bob
   Validated contracts
    Adjudicator at 0x079557d7549d7D44F4b00b51d2C532674129ed51
    AssetHolder at 0x923439be515b6A928cB9650d70000a9044e49E85
   Setting up listener for 0.0.0.0:8402
   Opening channel from Bob to Alice
   Received channel proposal from 0x307837303736353730316237396134653937336441626234623330413732663561383435663232463945
   Alice HandleNewChannel with id 0x644eba7aca469e34229de7b7f0ce12f31ef4bc30f17a35a7d95412e2d64296d0
   Accepted channel with id 0x644eba7aca469e34229de7b7f0ce12f31ef4bc30f17a35a7d95412e2d64296d0
   Bob HandleNewChannel with id 0x644eba7aca469e34229de7b7f0ce12f31ef4bc30f17a35a7d95412e2d64296d0
   🎉 Opened channel with id 0x644eba7aca469e34229de7b7f0ce12f31ef4bc30f17a35a7d95412e2d64296d0 
   Alice HandleUpdate Bals=[15000000000000000000, 5000000000000000000]
   HandleAdjudicatorEvent called id=0x644eba7aca469e34229de7b7f0ce12f31ef4bc30f17a35a7d95412e2d64296d0
   HandleAdjudicatorEvent called id=0x644eba7aca469e34229de7b7f0ce12f31ef4bc30f17a35a7d95412e2d64296d0
   Waiting for Alice
   Waiting for Bob

.. warning::
   | Running the code twice will produce different addresses since the state of the chain changed.
   | Always restart the chain if you need a deterministic testing environment.


The *ganache-cli* window will output the two deploy transactions.
The first for ~2M gas is the *Adjudicator*

.. code-block:: console

   Transaction: 0xe3b4e79293d042e264224fe64f1028e4a1c7da02ba8d63f9a125081479e83d2f
   Contract created: 0x079557d7549d7d44f4b00b51d2c532674129ed51
   Gas usage: 2090042
   Block Number: 1
   Block Time: Wed Jan 13 2021 16:40:28 GMT+0100 (Central European Standard Time)

and then the *AssetHolder* for ~870K gas

.. code-block:: console

   Transaction: 0x1fb382d4640a1fa986a1d2c6451dfbcb5d86bd00ac05bc0a091294c002fb0c09
   Contract created: 0x923439be515b6a928cb9650d70000a9044e49e85
   Gas usage: 870103
   Block Number: 2
   Block Time: Wed Jan 13 2021 16:40:29 GMT+0100 (Central European Standard Time)

.. note::
   The transactions are really quick on the local chain. On a testnet or main-chain each transaction would take about 15 seconds.

The following two transactions are the funding calls on the `AssetHolder`:

.. code-block:: console

   Transaction: 0xdfd0159e32032dc472012fdfcd2aa20847a0ab82059b7233140da13490bd47d7
   Gas usage: 44560
   Block Number: 3
   Block Time: Wed Jan 13 2021 16:40:29 GMT+0100 (Central European Standard Time)

Next is the `concludeFinal` call on the `Adjudicator`. It uses more gas than a normal transaction since it executes the conclude logic.

.. code-block:: console

   Transaction: 0xdffaa6a29d1c452e071468778fbf674d3137f740eb4bd67380e47aac3ce5b0fb
   Gas usage: 141827
   Block Number: 5
   Block Time: Wed Jan 13 2021 16:40:30 GMT+0100 (Central European Standard Time)

Finally both participants withdraw their funds:

.. code-block:: console

   Transaction: 0x193681cc0d19639a1f92b9884c7a25e542bf3e609368df83b52d043ecc344c0c
   Gas usage: 32731
   Block Number: 6
   Block Time: Wed Jan 13 2021 16:40:30 GMT+0100 (Central European Standard Time)
