Client
======
The Client is where all of the participant's logic comes together and, most importantly, where we implement the functionality for opening new Channels.
We put the code of this section in `client/client.go`.
Note, that the three self-explanatory functions `startWatching()`, `AcceptedChannel()`, `Shutdown()` are also implemented here.

Structure
~~~~~~~~~~~~~~~~~~
The core of our `PaymentClient` is `client.Client` (`perunClient`) that comes with go-perun.
We call it the "Perun Client", because it is the central controller to interact with the state channel network the Client participates in.

Then, the `account`, where the Client's funds are located, is required.
Additionally, we define the type of asset we expect our payment-channel(s) to use.
Multi-asset channels are possible, but one type of asset is sufficient in our case (Ethereum).
Finally, we utilize a go channel `channels` to store the Channels the Client is participating in.

.. code-block:: go

    // PaymentClient is a payment channel client.
    type PaymentClient struct {
        perunClient *client.Client       // The core Perun client.
        account     wallet.Address       // The account we use for on-chain and off-chain transactions.
        currency    channel.Asset        // The currency we expect to get paid in.
        channels    chan *PaymentChannel // Accepted payment channels.
    }

Setup
~~~~~
Let us create the constructor for our `PaymentClient` then.
The constructor requires six arguments to do so:

The `bus`, is the central message bus over which all clients of a channel network communicate.
The wallet `w`, is the Client's wallet, and address `acc` represents the address of the Ethereum account being used.
`nodeURL` and `chainID` indicate which blockchain the Client wants to connect to.
Finally, the deployed Adjudicator and AssetHolder contracts are given as address with `adjudicator` and `asset`.

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

First, we need to enable the Client to send on-chain transactions to interact with the smart contracts.
We do this by creating the so-called Contract Backend `cb` dependent on the chain parameters and the Clients wallet (for signing).

.. code-block:: go

    // Create Ethereum client and contract backend.
    cb, err := CreateContractBackend(nodeURL, chainID, w)
    if err != nil {
        return nil, fmt.Errorf("creating contract backend: %w", err)
    }

In order to ensure the correct contracts got deployed, we validate the given Adjudicator and AssetHolder contracts.
Please consider the criticality of this step because a manipulated/broken contract puts the Clients funds at risk.
Go-perun comes with two handy functionalities here:

`ethchannel.ValidateAdjudicator()` and `ethchannel.ValidateAssetHolderETH()` both checking the respective bytecode of the contract at the given address.
Note that the validation of the AssetHolder requires both addresses because this contract's code depends on the adjudicator.

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

We use `adj` for setting up a `watcher` that will allow the underlying Perun Client to constantly look for disputes on specific Channels and trigger reactions accordingly.

.. code-block:: go

    // Setup dispute watcher.
    watcher, err := local.NewWatcher(adj)
    if err != nil {
        return nil, fmt.Errorf("intializing watcher: %w", err)
    }

Then we create the Perun Client with the previously created (and partly given) components and ultimately generate the PaymentClient.
Note that the channel registry `channels` is initialized with a map that pairs the individual `PaymentChannel` with their channel ID.
We will look at the `PaymentChannel` implementation in the Channel section. # TODO: Add link

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
        channels:    map[channel.ID]*PaymentChannel{},
    }

Before returning the constructed `PaymentClient`, we start the Handler, which is the routine that handles channel proposals and channel update requests via callbacks.
We will take a look at the routines in the Handle section. # TODO: Add link

.. code-block:: go

    go perunClient.Handle(c, c)

    return c, nil
    }



Open Channel
~~~~~~~~~~~~~

We use `OpenChannel()` for allowing the Client to propose a new `PaymentChannel` to a `peer` by giving the peer's Client as an argument.
Additionally, the `amount` can be specified, which we are using in our implementation to set the proposer's starting balance.
In our case, we do not expect the receiver to put funds in the channel.
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
        initAlloc.SetAssetBalances(c.currency, []channel.Bal{
            new(big.Int).SetUint64(amount), // Our initial balance.
            big.NewInt(0),                  // Peer's initial balance.
        })

Next, we prepare the channel proposal.
The challenge duration is set to 10 seconds, giving the receiving party enough time to respond.
Then we use go-perun's `client.NewLedgerChannelProposal()` to create the proposal by giving the challenge duration, the Clients wallet address, the initial balances, and the channel participants.

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

The watcher's responsibility is that if an old state is registered, the on-chain state is refuted by registering the most recent states available.
The watcher is go-perun's way of allowing the Client to react to malicious peers and protect their funds.

.. toctree::
   :hidden:
