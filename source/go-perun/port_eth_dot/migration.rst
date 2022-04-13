.. _payment_client_on_polkadot:

Migrating from Ethereum to Polkadot
===================================

In order to make our :ref:`payment channel implementation <payment_tutorial_intro>` work on Polkadot we utilize the `perun-polkadot-backend <https://github.com/perun-network/perun-polkadot-backend>`_.
Most changes are done in the ``PaymentClient`` and its setup.
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
We replace ``CreateContractBackend`` with ``dot.NewAPI``, which acts as our chain connection given the ``nodeURL`` and ``networkId``.
Then, we use the resulting ``api`` object to create a ``Pallet`` from which we derive a new ``Funder`` and ``Adjudicator``.

.. literalinclude:: ../../perun-examples/payment-channel-dot/client/client.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel-dot/client/client.go#L45>`__
    :language: go
    :lines: 44-62

We set up the dispute ``watcher`` and create the ``perunClient`` to instantiate the full ``PaymentClient``.
Notice that we use the Polkadot specific wallet ``dotwallet.Wallet`` and asset ``dotchannel.Asset`` here.

.. literalinclude:: ../../perun-examples/payment-channel-dot/client/client.go
    :language: go
    :lines: 64-87

Setup
.....
We apply the following changes to ``util.go``.

**General.** The ``deployContracts`` function is omitted as the Perun Pallet is predeployed at node startup and therefore no contract deployment will be necessary.
Also, the ``balanceLogger`` is updated to work with Polkadot addresses.

**Client setup.** The function ``setupPaymentClient`` is adapted to suit the new ``paymentClient`` constructor.
Most notably, we create a Polkadot-specific wallet via ``dotwallet.NewWallet`` and adapt the constructor's parameters.

Run
---
We slightly adapt the demo scenario in ``main.go``.

**Environment.** The following constants describe the updated test environment.

.. literalinclude:: ../../perun-examples/payment-channel-dot/main.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel-dot/main.go#L22>`__
    :language: go
    :lines: 22-30

**Main function.** There are only minor adjustments made to the scenario sequence:

- The contract deployment is removed.
- We use ``blockQueryDepth`` in the ``setupPaymentClient`` call. This constant specifies how many blocks an event subscription scans for past events.

.. note::
    On our `Polkadot node <https://github.com/perun-network/perun-polkadot-node>`_, Alice and Bob start with *1.153 MDot* each. Hence we use a higher balance for funding and payments in ``main.go``.

.. literalinclude:: ../../perun-examples/payment-channel-dot/main.go
    :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel-dot/main.go#L35>`__
    :language: go
    :lines: 32-66

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