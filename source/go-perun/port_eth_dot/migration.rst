.. _payment_client_on_polkadot:

Migrating from Ethereum to Polkadot
===================================

In order to make our :ref:`payment channel implementation <payment_tutorial_intro>` work on Polkadot we utilize the `perun-polkadot-backend <https://github.com/perun-network/perun-polkadot-backend>`_.
Most changes are done in the ``PaymentClient`` & its setup.
The actual ``PaymentChannel`` implementation stays the same.

Most notably, we don't need to deploy smart contracts like the *Adjudicator* and *AssetHolder* anymore.
All necessary contracts are provided by the `perun-polkadot-pallet <https://github.com/perun-network/perun-polkadot-pallet>`_ which is deployed on the `perun-polkadot-node <https://github.com/perun-network/perun-polkadot-node>`_ we are using as our local test chain.

.. note::
    *Pallets* are modules that act as building blocks for constructing unique blockchains.
    Each pallet contains domain-specific logic.
    The *Perun Polkadot Pallet* provides *go-perun* state channels for all Substrate compatible blockchains.


Dependencies
------------
Again, we require *Go* as described in the :ref:`payment channel dependencies <payment_tutorial_deps>`.

Source Code
...........
This tutorial's source code is available at `perun-examples/payment-channel-dot <https://github.com/perun-network/perun-examples/tree/master/payment-channel-dot>`_.

.. code-block:: bash

   # Download repository.
   git clone https://github.com/perun-network/perun-examples.git
   cd perun-examples/payment-channel-dot

Docker
......
For the Polkadot part of the tutorial, we require *docker* to run our local `perun-polkadot-node <https://github.com/perun-network/perun-polkadot-node>`_.
You can find installation instructions `here <https://docs.docker.com/engine/install/>`_.

.. code-block:: bash

   # Check that docker is installed.
   docker -v

Changes
-------
The following modifications take the `Ethereum payment channel <https://github.com/perun-network/perun-examples/tree/master/payment-channel>`_ implementation as a foundation.

Client
......

**Utilities.**
We make adjustments to ``client/util.go`` first.
As we are on Polkadot now, we replace the conversion functions ``EthToWei``/``WeiToEth`` with ``DotToPlanck``/``PlanckToDot``.
Also, we drop the ``CreateContractBackend`` function.

**Constructor.**
Then we take a look at ``SetupPaymentClient`` in ``client/client.go``.
Replacing ``CreateContractBackend`` is ``dot.API``, which acts as our chain connection by giving the ``nodeURL`` and ``networkId``.
Then, we use the generated ``api`` to connect to our ``Pallet`` from which we bootstrap a new ``Funder`` and ``Adjudicator``.

.. code-block:: go

    // SetupPaymentClient creates a new payment client.
    func SetupPaymentClient(
        bus wire.Bus, // bus is used of off-chain communication.
        w *dotwallet.Wallet, // w is the wallet used for signing transactions.
        acc wallet.Account, // acc is the address of the account to be used for signing transactions.
        nodeURL string, // nodeURL is the URL of the blockchain node.
        networkId dot.NetworkID, // networkId is the identifier of the blockchain.
        queryDepth types.BlockNumber, // queryDepth is the number of blocks being evaluated when looking for events.
    ) (*PaymentClient, error) {
        // Connect to backend.
        api, err := dot.NewAPI(nodeURL, networkId)
        if err != nil {
            panic(err)
        }

        // Create Perun pallet and generate funder + adjudicator from it.
        perun := pallet.NewPallet(pallet.NewPerunPallet(api), api.Metadata())
        funder := pallet.NewFunder(perun, acc, 3)
        adj := pallet.NewAdjudicator(acc, perun, api, queryDepth )


We set up the dispute ``watcher`` and create the ``perunClient`` to instantiate the full ``PaymentClient``.
Notice that we use the Polkadot specific wallet ``dotwallet`` and asset ``dotchannel.Asset`` here.

.. code-block:: go

        // Setup dispute watcher.
        watcher, err := local.NewWatcher(adj)
        if err != nil {
            return nil, fmt.Errorf("intializing watcher: %w", err)
        }

        // Setup Perun client.
        waddr := dotwallet.AsAddr(acc.Address())
        perunClient, err := client.New(waddr, bus, funder, adj, w, watcher)
        if err != nil {
            return nil, errors.WithMessage(err, "creating client")
        }

        // Create client and start request handler.
        c := &PaymentClient{
            perunClient: perunClient,
            account:     waddr,
            currency:    &dotchannel.Asset,
            channels:    make(chan *PaymentChannel, 1),
        }

        go perunClient.Handle(c, c)
        return c, nil
    }

Setup
.....
We make some changes in ``util.go``:

**General.** The ``deployContracts`` function is omitted as no contract deployment will be necessary.
Also, the ``balanceLogger`` is updated to work with Polkadot addresses.

**Client setup.** ``setupPaymentClient`` is adapted to suit the new ``paymentClient`` constructor.
Most notably, we initialize a new Polkadot wallet ``dotwallet`` using the ``privateKey`` and propagate all parameters to the ``PaymentClient``.

Run
---
We slightly adapt the demo scenario in ``main.go``.

**Environment.** The following constants describe the updated test environment.

.. code-block:: none

    const (
        chainURL        = "ws://127.0.0.1:9944"
        networkID       = 42
        blockQueryDepth = 100

        // Private keys.
        keyAlice = "0xe5be9a5092b81bca64be81d212e7f2f9eba183bb7a90954f7b76361f6edb5c0a"
        keyBob   = "0x398f0c28f98885e046333d4a41c19cee4c37368a9832c6502f6cfd182e2aef89"
    )

**Main function.** There are only minor adjustments made to the scenario sequence:

- The contract deployment is removed.
- We use ``blockQueryDepth`` in the ``setupPaymentClient`` call.

.. note::
    On our `Polkadot node <https://github.com/perun-network/perun-polkadot-node>`_, Alice and Bob start with *1.153 MDot* each. Hence we use a higher balance for funding and payments in ``main.go``.

.. code-block:: go

    // main runs a demo of the payment client. It assumes that a blockchain node is
    // available at `chainURL` and that the accounts corresponding to the specified
    // secret keys are provided with sufficient funds.
    func main() {
        // Setup clients.
        log.Println("Setting up clients.")
        bus := wire.NewLocalBus() // Message bus used for off-chain communication.
        alice := setupPaymentClient(bus, chainURL, networkID, blockQueryDepth, keyAlice)
        bob := setupPaymentClient(bus, chainURL, networkID, blockQueryDepth, keyBob)

        // Print balances before transactions.
        l := newBalanceLogger(chainURL, networkID)
        l.LogBalances(alice.WalletAddress(), bob.WalletAddress())

        // Open channel, transact, close.
        log.Println("Opening channel and depositing funds.")
        chAlice := alice.OpenChannel(bob.WireAddress(), 100000)
        chBob := bob.AcceptedChannel()

        log.Println("Sending payments...")
        chAlice.SendPayment(50000)
        chBob.SendPayment(25000)
        chAlice.SendPayment(25000)

        log.Println("Settling channel.")
        chAlice.Settle() // Conclude and withdraw.
        chBob.Settle()   // Withdraw.

        // Print balances after transactions.
        l.LogBalances(alice.WalletAddress(), bob.WalletAddress())

        // Cleanup.
        alice.Shutdown()
        bob.Shutdown()
    }

Run from the command line
.........................
To run the example from the command line, start the local blockchain by calling the `perun-polkadot-node <https://github.com/perun-network/perun-polkadot-node>`_.
Make sure the port ``-p`` matches with the one of the ``chainURL`` in the environment constants.

.. code-block:: bash

    docker run --rm -it -p 9944:9944 ghcr.io/perun-network/polkadot-test-node

In a second terminal, run the demo:

.. code-block:: bash

    cd payment-channel-dot/
    go run .

If everything works, you should see the following output.

.. code-block:: none

    2022/04/11 15:04:52 Setting up clients.
    2022/04/11 15:04:52 Connecting to ws://127.0.0.1:9944...
    2022/04/11 15:04:52 Connecting to ws://127.0.0.1:9944...
    2022/04/11 15:04:52 Connecting to ws://127.0.0.1:9944...
    2022/04/11 15:04:52 Client balances (DOT): [1.153 MDot 1.153 MDot]
    2022/04/11 15:04:52 Opening channel and depositing funds.
    2022/04/11 15:04:54 Sending payments...
    2022/04/11 15:04:54 Settling channel.
    2022/04/11 15:04:54 Adjudicator event: type = *channel.ConcludedEvent, client = 0x8eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48
    2022/04/11 15:04:59 Adjudicator event: type = *channel.ConcludedEvent, client = 0xd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d
    2022/04/11 15:05:05 Client balances (DOT): [1.103 MDot 1.203 MDot]

With this, we conclude the migration tutorial.