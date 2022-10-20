.. _payment_client:

Client
=======

The client object provides methods for opening new channels and transacting on them.
Its implementation will be placed in package ``client``.

.. code-block:: go

    package client

.. _payment_client_constructor:

Constructor
-----------

The main part of our payment channel client is placed in ``client/client.go``.
Our client is of type ``PaymentClient`` and holds the fields described below.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel/client/client.go#L41>`__
   :language: go
   :lines: 40-46

.. note::

   *Go-perun* allows using **different accounts for on-chain and off-chain transactions** and also supports **multi-asset channels**. However, we will stick to one account and one asset for simplicity.

We first create the constructor for our ``PaymentClient``, which takes a number of parameters as described below.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel/client/client.go#L49>`__
   :language: go
   :lines: 48-57

Before we can create the payment channel client, we need to create a Perun client, which requires setting up the following components first.

**Contract backend.**
The contract backend is used for sending on-chain transactions to interact with the smart contracts.
We create a new contract backend ``cb`` by using the function ``CreateContractBackend``, which we explain in the :ref:`utility section <client_utility>`.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 58-62

**Contract validation.**
*Go-perun* features two types of smart contracts: the *Adjudicator* and the *Asset Holder*.
The Adjudicator is the central contract for dispute resolution.
An Asset Holder handles asset deposits and payouts for a certain type of asset.
To ensure that the provided addresses point to valid smart contracts, we validate the contract code at these addresses by using ``ValidateAdjudicator`` and ``ValidateAssetHolderETH``.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 64-72

.. important::
    The validity of the smart contracts is crucial as a manipulated or broken contract puts the client's funds at risk.

.. note::
   We use ``ValidateAssetHolderETH`` because we use ETH as the payment channel's currency.
   For validating an ERC20 asset holer, we would use ``ValidateAssetHolderERC20``.
   Note that asset holder validation also requires an Adjudicator address as input.
   This is because an Asset Holder is always associated with an Adjudicator, and this relation is checked during contract validation.

**Funder.**
Next, we create the ``Funder`` component, which will be used by the client to deposit assets into a channel.
We first create a new funder ``funder`` using method ``NewFunder``.
We then create a depositor ``dep`` for the asset type ETH by calling ``NewETHDepositor``.
We then use ``funder.RegisterAsset`` to tell the funder how assets of that type are funded and which account should be used for sending funding transactions.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 74-78

.. note::

   Different types of assets require different funded transactions and therefore require different depositor types.
   For example, an ERC20 token is funded using a depositor of type ``ERC20Depositor``.

**Adjudicator.**
Next, we use *go-perun*'s ``NewAdjudicator`` method to create a local Adjudicator instance, ``adj``, which will be used by the client to interact with the Adjudicator smart contract.
Here, ``acc`` denotes the address of the account that will receive the payout when a channel is closed, which can also later be changed using the ``Receiver`` property.
The parameter ``ethAcc`` defines the account that is used for sending on-chain transactions.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 80-81

**Watcher.**
The responsibility of the watcher component is to watch the Adjudicator smart contract for channel disputes and react accordingly.
We create a new watcher of type ``local.Watcher`` by calling ``local.NewWatcher`` with the adjudicator instance ``adj`` as input.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 83-87

.. note::

   The watcher used here is a ``local.Watcher`` and runs only as long as the client is online.
   However, you can also implement a remote watcher that runs independently and can handle disputes even when clients are offline.

**Perun client.**
Now we have all components ready to create a Perun client.
We create a new Perun client by calling ``client.New``, where we provide the client's network identity ``waddr`` and the previously constructed components as input.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 89-95

**Payment client.**
Finally, we construct a payment client ``c`` that holds the Perun client, the account, and the asset.
We then start the message handler of the Perun client and set our payment client ``c`` as the channel proposal and update handler by calling ``perunClient.Handle`` with ``c`` as input.
To handle requests, the payment client implements the methods ``HandleProposal`` and ``HandleUpdate`` in ``client/handle.go``.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 97-104

Open channel
------------

The method ``OpenChannel`` allows a client to propose a new payment channel to another client.
It gets as input the client's network address ``peer`` and an ``amount``, which defines the proposer's starting balance in the channel.
We do not expect the receiver to put funds into the channel in our case.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 108-109
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel/client/client.go#L109>`__

**Channel participants.**
The channel participants are defined as a list of wire addresses.
The proposer must always go first.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 110-113

**Initial balance.**
The initial balance allocation is constructed by using *go-perun*'s ``channel.NewAllocation``, which returns a new allocation `initAlloc` for the given number of participants and asset type.
With ``initAlloc.SetAssetBalances`` we set the actual initial balances.
Note that the proposer always has index 0 and the receiver index 1.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 115-120

**Challenge duration.**
The challenge duration determines the duration after which a funding or dispute timeout occurs.
If the channel is not funded within the funding duration, channel opening will fail.
If a channel dispute is raised, channel participants can only respond within the dispute duration.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 123-123

.. _payment_challenge_duration_warning:

.. attention::
    Note that in a real-world application, one would typically set a much higher dispute duration in order to give all clients an appropriate chance to respond to disputes.
    Depending on the application context, the dispute duration may be several hours or even days.

**Channel proposal message.**
Next, we prepare the channel proposal message.
We use *go-perun*'s ``client.NewLedgerChannelProposal`` to create the proposal message by giving the challenge duration, the client's wallet address, the initial balances, and the channel participants as input.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 124-132

**Propose channel.**
The ``proposal`` is then sent by calling ``perunClient.ProposeChannel``, which runs the channel opening protocol and returns a new Perun channel ``ch`` on success.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 134-138

**Start watcher.**
We instruct the watcher to start watching for disputes concerning ``ch`` by calling ``c.startWatching``, which we describe in the :ref:`utility section <client_watcher>`.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 139-141

**Create payment channel.**
Finally, we construct the payment channel from the Perun channel and the currency.
We describe the implementation of type ``PaymentChannel`` in the :ref:`channel section <client_channel>`.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 142-144

.. _payment_client_handle_proposals:

Handle proposal
...............

The client will receive incoming channel proposals via ``HandleProposal``.

.. literalinclude:: ../../perun-examples/payment-channel/client/handle.go
   :language: go
   :lines: 27-28
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel/client/handle.go#L28>`__

**Check proposal.**
Before a channel proposal is accepted, it is essential to check its parameters.
If any of the checks fail, we reject the proposal by using ``r.Reject``.
You can add additional checks to the logic, but the checks below are sufficient for our simple use case.

.. literalinclude:: ../../perun-examples/payment-channel/client/handle.go
   :language: go
   :lines: 29-52

**Accept proposal.**
To accept the channel proposal, we follow two steps:
First, we create the accept message, including the client's address and a random nonce.
This is done by simply calling ``lcp.Accept``.
Then we send the accept message via ``r.Accept``.

.. literalinclude:: ../../perun-examples/payment-channel/client/handle.go
   :language: go
   :lines: 54-64

If this is successful, we call ``startWatching`` for automatic dispute handling.
Finally, we create a payment channel and push it on to ``c.channels``.

.. literalinclude:: ../../perun-examples/payment-channel/client/handle.go
   :language: go
   :lines: 65-70

**Fetch accepted channel.**
We define ``AcceptedChannel`` for fetching channels that the channel proposal handler accepted asynchronously.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 156-159
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel/client/client.go#L157>`__


.. _client_channel:

Payment channel
---------------

We implement the type ``PaymentChannel`` that wraps a Perun channel and provides convenience functions for interacting with a payment channel.
We put this functionality in ``client/channel.go``.

.. literalinclude:: ../../perun-examples/payment-channel/client/channel.go
   :language: go
   :lines: 11-23
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel/client/channel.go#L12>`__


Send Payment
............
Sending a payment is a proposal to change the balances of a channel so that the sender's balance is reduced and the receiver's balance is increased.
By doing the opposite, we can realize payment requests.
We create ``SendPayment`` to implement our basic payment logic here, which expects as input the ``amount`` that is to be transferred to the peer.
We use *go-perun*'s ``Channel.UpdateBy`` for proposing the desired channel state update.
We use *go-perun*'s ``TransferBalance`` function to automatically subtract the given ``amount`` from the proposer's balance and add it to the receiver's balance.

.. literalinclude:: ../../perun-examples/payment-channel/client/channel.go
   :language: go
   :lines: 25-39
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel/client/channel.go#L26>`__

.. note::
   Note that any update must maintain the overall sum of funds inside the channel. Otherwise, the update is blocked.

Handle Update
.............
The client receives channel update proposals via the callback method ``HandleUpdate``.
The method gets as input the current channel state, the proposed update, and a responder object for either accepting or rejecting the update.

.. literalinclude:: ../../perun-examples/payment-channel/client/handle.go
   :language: go
   :lines: 72-73
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel/client/handle.go#L73>`__

We first check if the proposed update satisfies our payment channel conditions, i.e., that it increases our balance.
If this is not the case, we reject using ``r.Reject``.

.. literalinclude:: ../../perun-examples/payment-channel/client/handle.go
   :language: go
   :lines: 74-91

If all checks above pass, we accept the update by calling ``r.Accept``.

.. literalinclude:: ../../perun-examples/payment-channel/client/handle.go
   :language: go
   :lines: 93-98

.. _payment_client_settle:

Settle Channel
..............
Settling a channel means concluding the channel state and withdrawing our final balance.
These steps are realized by *go-perun*'s ``Channel.Settle``.
To enable fast and cheap settlement, we try to finalize the channel via an off-chain update first.
We create a method ``Settle``, that first tries to finalize the channel off-chain using ``Channel.UpdateBy`` and then closes the channel on-chain using *go-perun*'s ``Channel.Settle``.

.. literalinclude:: ../../perun-examples/payment-channel/client/channel.go
   :language: go
   :lines: 41-62
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel/client/channel.go#L42>`__

.. _client_utility:

Utilities
---------
In this section, we implement several utility functions that we were already using above and will be using in the following.
We put the following code in ``client/client.go`` and ``client/util.go``.

.. _client_watcher:

Start watching
..............
The watcher is responsible for detecting the registration of an old state and refuting it with the most current state available.
To start the dispute watcher for a given channel ``ch``, we call ``ch.Watch``, which expects as input an on-chain event handler implementing ``HandleAdjudicatorEvent`` to which events will be forwarded.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 146-154
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel/client/client.go#L147>`__

In our case, the client will handle the on-chain events and print them to the standard output.

.. literalinclude:: ../../perun-examples/payment-channel/client/handle.go
   :language: go
   :lines: 100-103
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel/client/handle.go#L101>`__

Client shutdown
...............
To allow the client to shut down in a managed way, we define ``Shutdown``, which gives *go-perun* the opportunity to free-up resources.

.. literalinclude:: ../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 161-164
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel/client/client.go#L162>`__


Contract backend
................
The contract backend allows the client to interact with smart contracts on the blockchain.
We put this code in ``client/util.go``

Our constructor of the contract backend requires three parameters.
``nodeURL`` and ``chainID`` specify the blockchain to be used, and ``w`` is the wallet that will be used for signing transactions.

.. literalinclude:: ../../perun-examples/payment-channel/client/util.go
   :language: go
   :lines: 28-34
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel/client/util.go#L30>`__

Using the ``chainID``, we start by creating an ``EIP155Signer`` provided by go-ethereum.
We can now create a ``channel.Transactor`` by calling ``swallet.NewTransactor`` with inputting the wallet and the signer.
The ``transactor`` will be used for signing on-chain transactions.

.. literalinclude:: ../../perun-examples/payment-channel/client/util.go
   :language: go
   :lines: 35-37

The contract backend uses a go-ethereum client ``ethclient.Client`` for communicating with the blockchain, which we create using ``ethclient.Dial`` with input ``nodeURL``.
We then call ``NewContractBackend`` with the ``ethClient``, ``transactor``, and ``txFinalityDepth`` as input.
The value ``txFinality`` determines how many blocks are required to confirm a transaction and is set to 1 by default.

.. literalinclude:: ../../perun-examples/payment-channel/client/util.go
   :language: go
   :lines: 38-44

Conversion between Ether and Wei
................................
Wei is the smallest unit of Ether (1 Ether = 10^18 Wei).
Transaction amounts are usually defined in Wei to maintain high precision.
However, for better usability, we provide functions that take an amount in Ether.
To accommodate for this, we implement ``EthToWei`` and ``WeiToEth`` to convert between these different denominations.

.. literalinclude:: ../../perun-examples/payment-channel/client/util.go
   :language: go
   :lines: 55-71
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/4a225436710bb47d805dbc7652beaf27df74941f/payment-channel/client/util.go#L57>`__