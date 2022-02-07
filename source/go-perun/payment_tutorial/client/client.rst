.. _client:

Client
======
The client is where all of the participant's logic comes together and, most importantly, where we implement the functionality for opening/proposing new channels.
We start by giving a detailed description of the client implementation and end this section with implementing some utility functionality.

Implementation
~~~~~~~~~~~~~~
We put the following code in `client/client.go`.

Structure
---------
The core of our `PaymentClient` is the `perunClient` which is of type `client.Client` from go-perun.
We call it the "Perun Client", because it is the central controller to interact with the state channel network the client participates in.
`PaymentClient` is simply a wrapper that expands the base Perun Client with our individual payment functionality.

Added to this is the `account`, where the client's funds are located.
Then we also define the type of asset `currency` we expect our payment channel(s) to use.
Multi-asset channels are possible, but one type of asset is sufficient in our case.
Finally, we utilize a go channel `channels` to store the client's `PaymentChannel` (which we will define in the next section).

.. literalinclude:: ../../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 40-46

.. note::

    We will use `context.TODO()` and `panic(err)` to keep the code in simple. In production code, one should always use proper context and handle errors appropriately.

Constructor
-----------
Let us create the constructor for our `PaymentClient` then.
Six arguments are required:

The `bus`, is the central message bus over which all clients of a channel network communicate.
The wallet `w`, is the client's wallet, and address `acc` represents the address of the Ethereum account being used for on-chain and off-chain transactions.
`nodeURL` and `chainID` indicate which blockchain the client wants to connect to.
Finally, the deployed Adjudicator and AssetHolder contracts are given as addresses with `adjudicator` and `asset`.

.. literalinclude:: ../../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 48-57

First, we need to enable the client to send on-chain transactions to interact with the smart contracts.
We do this by creating the so-called contract backend `cb` dependent on the chain parameters and the clients wallet (for signing).
`CreateContractBackend()` is defined at the end of the following :ref:`Utility section <client-utility>`, where all its functionality is described in greater detail.

.. literalinclude:: ../../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 58-62

To ensure the correct contracts got deployed, we validate the given Adjudicator and AssetHolder contracts.

.. warning::
    Please consider the criticality of the validation because a manipulated/broken contract puts the Client's funds at risk.

Go-perun comes with two handy functionalities here:

`ethchannel.ValidateAdjudicator()` and `ethchannel.ValidateAssetHolderETH()` are both checking the respective bytecode of the contract at the given address.
Note that the validation of the AssetHolder requires both addresses because this contract's code depends on the Adjudicator.

.. literalinclude:: ../../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 64-72

Next, we enable the Client to put his Ethereum funds in the AssetHolder.
Go-perun comes with `ethchannel.NewFunder()` and `ethchannel.NewETHDepositor()` to help us here:

We create the `funder` by calling `ethchannel.NewFunder()` with the contract backend.
Because we expect the AssetHolder to hold Ethereum as our asset here, we create an Ethereum depositor `dep` by calling `ethchannel.NewETHDepositor()`.
Finally, the depositor and the Client’s account are registered for the specified asset inside `funder`.
This instructs the `funder` that deposits for the asset of the AssetHolder will be sent using the depositors from the specified account in the funding process.

.. literalinclude:: ../../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 74-78

Further, we use go-perun's `ethchannel.NewAdjudicator()` with the contract backend to create an interactable in-code representation of the Adjudicator `adj`.

.. literalinclude:: ../../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 80-81

We use `adj` for setting up a `watcher` that will allow the underlying Perun Client to constantly look for disputes on specific channels and trigger reactions accordingly.

.. literalinclude:: ../../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 83-87

Then we create the Perun Client with the previously created (and partly given) components and ultimately generate the `PaymentClient`.
We will look at the `PaymentChannel` implementation in the :ref:`Channel section <client-channel>`.

.. literalinclude:: ../../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 89-102

.. _client-handler-mention:

Before returning the constructed `PaymentClient`, we start the Handler, which is the routine that handles channel proposals and channel update requests via callbacks.
We will take a look at the routines in the :ref:`Handle section <client-handle>`.

.. literalinclude:: ../../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 103-106


Open/Propose Channel
--------------------

We use `OpenChannel()` for allowing the Client to propose a new `PaymentChannel` to a `peer` by giving the peer's Client as an argument.
Additionally, the `amount` can be specified, which we are using in our implementation to set the proposer's starting balance.
We do not expect the receiver to put funds in the channel in our case.
This is implemented by calling go-perun's `channel.NewAllocation()` and `SetAssetBalances()`:

`channel.NewAllocation()` returns a new allocation `initAlloc` for the given number of participants and asset type.
With `initAlloc.SetAssetBalances()` we set the actual initial balances.
Note that the proposer always has index 0 and the receiver index 1.

.. literalinclude:: ../../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 108-120

Next, we prepare the channel proposal.
The challenge duration is set to 10 seconds, giving the receiving party time to respond.

.. warning::
    Note that the challenge duration is also used in the context of resolving disputes on the blockchain; therefore, this parameter is of high importance:

    Suppose Eve pushes an old state to the blockchain to settle it.
    In that case, Alice must be given enough time to notice this event and submit the most recent state to resolve the dispute and protect her funds.
    For example, ten seconds might not be enough, e.g., if Alice only comes online every few hours.
    Hence in real-world use cases, the challenge duration typically ranges from hours to multiple days or even weeks, depending on the assumptions regarding its peers.

We use go-perun's `client.NewLedgerChannelProposal()` to create the proposal by giving the challenge duration, the clients wallet address, the initial balances, and the channel participants.

.. literalinclude:: ../../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 122-132

The `proposal` is then sent by calling `ProposeChannel()` via the `perunClient`, which returns the respective channel object `ch`.
Before returning the new `PaymentChannel`, the watcher is instructed to start looking for disputes concerning `ch` via `startWatching()`.

.. literalinclude:: ../../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 134-144

More about the watcher's responsibility in the following.

.. _client-utility:

Utilities
~~~~~~~~~
Before we continue with the channel description, let's implement a few utility functions that we were already (party) using above and will be used in the following.
We put the following code in `client/client.go` and `client/util.go`.

Start Watching
--------------
The watcher is responsible for detecting the registration of an old state and refuting it by registering the most current state available.
This is go-perun's way of allowing the Client to react to possibly malicious peers and protect its funds.

To start the dispute watcher, we take the Channel we want to watch and call `.Watch()` on it.
It is essential to put this call into a separate goroutine to have it running in the background.
If for any reason the watching fails, we `panic` because the client is no longer protected against old states, and its channel funds might be at risk.

.. literalinclude:: ../../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 146-156



Access Channels & Shutdown Client
---------------------------------
For accessing the next Channel inside the channel registry, we define `AcceptedChannel()`.
This will become useful for the receiving client when fetching the channels the Handler accepted automatically.

.. literalinclude:: ../../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 158-161

To allow the client to shut down in a managed way, we define `Shutdown()`, which gives go-perun the opportunity to free-up resources.

.. literalinclude:: ../../../perun-examples/payment-channel/client/client.go
   :language: go
   :lines: 163-166


Contract Backend
----------------
We want our client to be able to access the blockchain for creating the payment channel.
The contract backend provides this functionality.
It is needed to send on-chain transactions, hence interacting with smart contracts.
We put this code in `client/util.go`

To initialize the contract backend, we need three arguments.
`nodeURL` and `chainID` indicate which blockchain the client wants to connect to, and `w` is the wallet the Contact Backend will use for signing transactions.

Using the `chainID`, we start by creating an `EIP155Signer` provided by go-ethereum.
We can now generate a `channel.Transactor` via go-perun's simple wallet `swallet` implementation and the `signer`.
This `transactor` will handle the generation of valid transactions.
For the last step, we require a go-ethereum client `ethclient.Client` that establishes the actual connection to the chain by dialing the `nodeURL`.
Finally we call `ethchannel.NewContractBackend()` with the `ethClient`, `transactor` (that includes the `signer`), and a `txFinalityDepth` constant.
This constant is set to 1 in our example and defines how many consecutive blocks a transaction must be included to be considered final.

.. literalinclude:: ../../../perun-examples/payment-channel/client/util.go
   :language: go
   :lines: 28-43

Ether <-> Wei
-------------
Wei is the smallest unit of Ether (1 Eth = 0,000000000000000001 Eth).
To formulate precise amounts, interactions with the chain & channel usually require the value given in Wei.

We want the clients to provide functions that take the amount in Ether for better understanding.
Therefore we create the two conversion functions `EthToWei` and `WeiToEth`.
Using these functions is, of course, optional. You could also do everything in Wei.

.. literalinclude:: ../../../perun-examples/payment-channel/client/util.go
   :language: go
   :lines: 50-65


.. toctree::
   :hidden:
