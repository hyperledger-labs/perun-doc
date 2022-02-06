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

.. code-block:: go

    // PaymentClient is a payment channel client.
    type PaymentClient struct {
        perunClient *client.Client       // The core Perun client.
        account     wallet.Address       // The account we use for on-chain and off-chain transactions.
        currency    channel.Asset        // The currency we expect to get paid in.
        channels    chan *PaymentChannel // Accepted payment channels.
    }


Constructor
-----------
Let us create the constructor for our `PaymentClient` then.
Six arguments are required:

The `bus`, is the central message bus over which all clients of a channel network communicate.
The wallet `w`, is the client's wallet, and address `acc` represents the address of the Ethereum account being used for on-chain and off-chain transactions.
`nodeURL` and `chainID` indicate which blockchain the client wants to connect to.
Finally, the deployed Adjudicator and AssetHolder contracts are given as addresses with `adjudicator` and `asset`.

.. code-block:: go

    // SetupPaymentClient creates a new payment client.
    func SetupPaymentClient(
        bus wire.Bus,
        w *swallet.Wallet,
        acc common.Address,
        nodeURL string,
        chainID uint64,
        adjudicator common.Address,
        asset ethwallet.Address,
    ) (*PaymentClient, error) {

First, we need to enable the client to send on-chain transactions to interact with the smart contracts.
We do this by creating the so-called Contract Backend `cb` dependent on the chain parameters and the clients wallet (for signing).
`CreateContractBackend()` is defined at the end of the following :ref:`Utility section <client-utility>`, where all its functionality is described in greater detail.

.. code-block:: go

    // Create Ethereum client and contract backend.
    cb, err := CreateContractBackend(nodeURL, chainID, w)
    if err != nil {
        return nil, fmt.Errorf("creating contract backend: %w", err)
    }

To ensure the correct contracts got deployed, we validate the given Adjudicator and AssetHolder contracts.

.. warning::
    Please consider the criticality of the validation because a manipulated/broken contract puts the Client's funds at risk.

Go-perun comes with two handy functionalities here:

`ethchannel.ValidateAdjudicator()` and `ethchannel.ValidateAssetHolderETH()` are both checking the respective bytecode of the contract at the given address.
Note that the validation of the AssetHolder requires both addresses because this contract's code depends on the Adjudicator.

.. code-block:: go

    // Validate contracts.
    err = ethchannel.ValidateAdjudicator(context.TODO(), cb, adjudicator)
    if err != nil {
        return nil, fmt.Errorf("validating adjudicator: %w", err)
    }
    err = ethchannel.ValidateAssetHolderETH(context.TODO(), cb, common.Address(asset), adjudicator)
    if err != nil {
        return nil, fmt.Errorf("validating adjudicator: %w", err)
    }


Next, we enable the Client to put his Ethereum funds in the AssetHolder.
Go-perun comes with `ethchannel.NewFunder()` and `ethchannel.NewETHDepositor()` to help us here:

We create the `funder` by calling `ethchannel.NewFunder()` with the Contract Backend.
Because we expect the AssetHolder to hold Ethereum as our asset here, we create an Ethereum depositor `dep` by calling `ethchannel.NewETHDepositor()`.
Finally, the depositor and the Client’s account are registered for the specified asset inside `funder`.
This instructs the `funder` that deposits for the asset of the AssetHolder will be sent using the depositors from the specified account in the funding process.

.. code-block:: go

    // Setup funder.
    funder := ethchannel.NewFunder(cb)
    dep := ethchannel.NewETHDepositor()
    ethAcc := accounts.Account{Address: acc}
    funder.RegisterAsset(asset, dep, ethAcc)

Further, we use go-perun's `ethchannel.NewAdjudicator()` with the Contract Backend to create an interactable in-code representation of the Adjudicator `adj`.

.. code-block:: go

    // Setup adjudicator.
    adj := ethchannel.NewAdjudicator(cb, adjudicator, acc, ethAcc)

We use `adj` for setting up a `watcher` that will allow the underlying Perun Client to constantly look for disputes on specific channels and trigger reactions accordingly.

.. code-block:: go

    // Setup dispute watcher.
    watcher, err := local.NewWatcher(adj)
    if err != nil {
        return nil, fmt.Errorf("intializing watcher: %w", err)
    }

Then we create the Perun Client with the previously created (and partly given) components and ultimately generate the `PaymentClient`.
We will look at the `PaymentChannel` implementation in the :ref:`Channel section <client-channel>`.

.. code-block:: go

    // Setup Perun client.
    waddr := ethwallet.AsWalletAddr(acc)
    perunClient, err := client.New(waddr, bus, funder, adj, w, watcher)
    if err != nil {
        return nil, errors.WithMessage(err, "creating client")
    }

    // Create client and start request handler.
    c := &PaymentClient{
        perunClient: perunClient,
        account:     waddr,
        currency:    &asset,
        channels:    make(chan *PaymentChannel, 1),
    }

.. _client-handler-mention:

Before returning the constructed `PaymentClient`, we start the Handler, which is the routine that handles channel proposals and channel update requests via callbacks.
We will take a look at the routines in the :ref:`Handle section <client-handle>`.

.. code-block:: go

    go perunClient.Handle(c, c)

    return c, nil
    }



Open/Propose Channel
--------------------

We use `OpenChannel()` for allowing the Client to propose a new `PaymentChannel` to a `peer` by giving the peer's Client as an argument.
Additionally, the `amount` can be specified, which we are using in our implementation to set the proposer's starting balance.
We do not expect the receiver to put funds in the channel in our case.
This is implemented by calling go-perun's `channel.NewAllocation()` and `SetAssetBalances()`:

`channel.NewAllocation()` returns a new allocation `initAlloc` for the given number of participants and asset type.
With `initAlloc.SetAssetBalances()` we set the actual initial balances.
Note that the proposer always has index 0 and the receiver index 1.

.. code-block:: go

       // OpenChannel opens a new channel with the specified peer and funding.
    func (c *PaymentClient) OpenChannel(peer *PaymentClient, amount uint64) PaymentChannel {
        // We define the channel participants. The proposer always has index 0. Here
        // we use the on-chain addresses as off-chain addresses, but we could also
        // use different ones.
        participants := []wire.Address{c.account, peer.account}

        // We create an initial allocation which defines the starting balances.
        initAlloc := channel.NewAllocation(2, c.currency) //TODO:go-perun balances should be initialized to zero
        initAlloc.SetBalance(c.currency, proposerIdx, new(big.Int).SetUint64(amount)) // Our initial balance.                        initAlloc.SetBalance(c.currency, proposerIdx, big.NewInt(0)) // Peer's initial balance.

Next, we prepare the channel proposal.
The challenge duration is set to 10 seconds, giving the receiving party time to respond.

.. warning::
    Note that the challenge duration is also used in the context of resolving disputes on the blockchain; therefore, this parameter is of high importance:

    Suppose Eve pushes an old state to the blockchain to settle it.
    In that case, Alice must be given enough time to notice this event and submit the most recent state to resolve the dispute and protect her funds.
    For example, ten seconds might not be enough, e.g., if Alice only comes online every few hours.
    Hence in real-world use cases, the challenge duration typically ranges from hours to multiple days or even weeks, depending on the assumptions regarding its peers.

We use go-perun's `client.NewLedgerChannelProposal()` to create the proposal by giving the challenge duration, the clients wallet address, the initial balances, and the channel participants.

.. code-block:: go

        // Prepare the channel proposal by defining the channel parameters.
        challengeDuration := uint64(10) // On-chain challenge duration in seconds.
        proposal, err := client.NewLedgerChannelProposal(
            challengeDuration,
            c.account,
            initAlloc,
            participants,
        )
        if err != nil {
            panic(err)
        }

The `proposal` is then sent by calling `ProposeChannel()` via the `perunClient`, which returns the respective channel object `ch`.
Before returning the new `PaymentChannel`, the watcher is instructed to start looking for disputes concerning `ch` via `startWatching()`.

.. code-block:: go

        // Send the proposal.
        ch, err := c.perunClient.ProposeChannel(context.TODO(), proposal)
        if err != nil {
            panic(err)
        }

        // Start the on-chain event watcher. It automatically handles disputes.
        c.startWatching(ch)

        return *newPaymentChannel(ch, c.currency)
    }

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

.. code-block:: go

    // startWatching starts the dispute watcher for the specified channel.
    func (c *PaymentClient) startWatching(ch *client.Channel) {
        go func() {
            err := ch.Watch(c)
            if err != nil {
                // Panic because if the watcher is not running, we are no longer
                // protected against registration of old states.
                panic(fmt.Sprintf("Watcher returned with error: %v", err))
            }
        }()
    }



Access Channels & Shutdown Client
---------------------------------
For accessing the next Channel inside the channel registry, we define `AcceptedChannel()`.
This will become useful for the receiving client when fetching the channels the Handler accepted automatically.

.. code-block:: go

    // AcceptedChannel returns the next accepted channel.
    func (c *PaymentClient) AcceptedChannel() *PaymentChannel {
        return <-c.channels
    }

To allow the client to shut down in a managed way, we define `Shutdown()`, which gives go-perun the opportunity to free-up resources.

.. code-block:: go

    // Shutdown gracefully shuts down the client.
    func (c *PaymentClient) Shutdown() {
        c.perunClient.Close()
    }


Contract Backend
----------------
We want our client to be able to access the blockchain for creating the payment channel.
The Contract Backend provides this functionality.
It is needed to send on-chain transactions, hence interacting with smart contracts.
We put this code in `client/util.go`

To initialize the Contract Backend, we need three arguments.
`nodeURL` and `chainID` indicate which blockchain the client wants to connect to, and `w` is the wallet the Contact Backend will use for signing transactions.

Using the `chainID`, we start by creating an `EIP155Signer` provided by go-ethereum.
We can now generate a `channel.Transactor` via go-perun's simple wallet `swallet` implementation and the `signer`.
This `transactor` will handle the generation of valid transactions.
For the last step, we require a go-ethereum client `ethclient.Client` that establishes the actual connection to the chain by dialing the `nodeURL`.
Finally we call `ethchannel.NewContractBackend()` with the `ethClient`, `transactor` (that includes the `signer`), and a `txFinalityDepth` constant.
This constant is set to 1 in our example and defines how many consecutive blocks a transaction must be included to be considered final.

.. code-block:: go

    // CreateContractBackend creates a new contract backend.
    func CreateContractBackend(
        nodeURL string,
        chainID uint64,
        w *swallet.Wallet,
    ) (ethchannel.ContractBackend, error) {
        signer := types.NewEIP155Signer(new(big.Int).SetUint64(chainID))
        transactor := swallet.NewTransactor(w, signer) //TODO:go-perun transactor should be spawnable from Wallet: Add method "NewTransactor"

        ethClient, err := ethclient.Dial(nodeURL)
        if err != nil {
            return ethchannel.ContractBackend{}, err
        }

        return ethchannel.NewContractBackend(ethClient, transactor, txFinalityDepth), nil
    }

.. toctree::
   :hidden:
