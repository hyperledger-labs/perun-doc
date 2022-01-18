Client
======
The Client is where all of the participants logic comes together and most importantly, where we implement the functionality for opening new Channels.
We put the code of this section in `client/client.go`.

Structure
~~~~~~~~~~~~~~~~~~
The core of our `PaymentClient` is `client.Client` (`perunClient`) that comes with go-perun.
We call it the "Perun Client", because it is the central controller to interact with the state channel network the client is participating in.

Additionally the `account`, in which the funds of the client are located, is needed. It is given as `wallet.Address`.

Then, we also define the type of Asset we expect our payment-channel(s) to use.
Multi-asset channels are possible but for our use-case one type of asset is sufficient (Ethereum).

Finally we utilize a map as `PaymentChannel` registry. Individual payment-channels can be identified here by their `channel.ID`.
We also need a mutex `channelsMtx` to ensure concurrency of `channels` in case of simultaneous access.

.. code-block:: go

    // PaymentClient is a payment channel client.
    type PaymentClient struct {
        perunClient *client.Client                 // The core Perun client.
        account     wallet.Address                 // The account we use for on-chain and off-chain transactions.
        currency    channel.Asset                  // The currency we expect to get paid in.
        channels    map[channel.ID]*PaymentChannel // A registry to store the channels.
        channelsMtx sync.RWMutex                   // A mutex to protect the channel registry from concurrent access.
    }

Setup
~~~~~
Let us create the constructor for our `PaymentClient` then.
For a secure instantiation (therefore channel creation/interaction afterwards), we need to communicate with the on-chain adjudicator and asset holder contract and validate them.
Then we need to register our desired asset and start watching for disputes on-chain. Not doing this could result in a loss of funds.
Finally we start up the Perun Client and connect it to the

.. code-block:: go

    // SetupPaymentClient creates a new payment client.
    func SetupPaymentClient(
        bus wire.Bus,
        w *swallet.Wallet,
        acc common.Address,
        nodeURL string,
        chainID uint64,
        adjudicator common.Address,
        assetHolder common.Address,
    ) (*PaymentClient, error) {


.. code-block:: go

    // Create Ethereum client and contract backend.
    cb, err := CreateContractBackend(nodeURL, chainID, w)
    if err != nil {
        return nil, fmt.Errorf("creating contract backend: %w", err)
    }


.. code-block:: go

    // Validate contracts.
    err = ethchannel.ValidateAdjudicator(context.TODO(), cb, adjudicator)
    if err != nil {
        return nil, fmt.Errorf("validating adjudicator: %w", err)
    }
    err = ethchannel.ValidateAssetHolderETH(context.TODO(), cb, assetHolder, adjudicator)
    if err != nil {
        return nil, fmt.Errorf("validating adjudicator: %w", err)
    }


The Funder will allow us to interact with the asset holder contract to deposit our Ethereum funds there.
We create `funder` by calling `ethchannel.NewFunder()` with the contract backend.
Then we fetch the Ethereum channel asset by calling `NewAsset()`.
Next, we create a Ethereum depositor `dep` by calling `ethchannel.NewETHDepositor()`.
Finally, the depositor and the client’s account are registered for the specified asset inside `funder`.

.. code-block:: go

    // Setup funder.
    funder := ethchannel.NewFunder(cb)
    asset := *NewAsset(assetHolder)
    dep := ethchannel.NewETHDepositor()
    ethAcc := accounts.Account{Address: acc}
    funder.RegisterAsset(asset, dep, ethAcc)


.. code-block:: go

    // Setup adjudicator.
    adj := ethchannel.NewAdjudicator(cb, adjudicator, acc, ethAcc)


.. code-block:: go

    // Setup dispute watcher.
    watcher, err := local.NewWatcher(adj)
    if err != nil {
        return nil, fmt.Errorf("intializing watcher: %w", err)
    }

.. code-block:: go

    // Setup Perun client.
    waddr := ethwallet.AsWalletAddr(acc)
    perunClient, err := client.New(waddr, bus, funder, adj, w, watcher)
    if err != nil {
        return nil, errors.WithMessage(err, "creating client")
    }

.. code-block:: go

    // Create client and start request handler.
    c := &PaymentClient{
        perunClient: perunClient,
        account:     waddr,
        currency:    &asset,
        channels:    map[channel.ID]*PaymentChannel{},
    }
    go perunClient.Handle(c, c)

    return c, nil
    }




Open Channel
~~~~~

.. code-block:: go

    // OpenChannel opens a new channel with the specified peer and funding.
    func (c *PaymentClient) OpenChannel(peer *PaymentClient, asset channel.Asset, amount uint64) PaymentChannel {
        // We define the channel participants. The proposer always has index 0. Here
        // we use the on-chain addresses as off-chain addresses, but we could also
        // use different ones.
        participants := []wire.Address{c.account, peer.account}

        // We create an initial allocation which defines the starting balances.
        initAlloc := channel.NewAllocation(2, asset) //TODO:go-perun balances should be initialized to zero
        initAlloc.SetAssetBalances(asset, []channel.Bal{
            new(big.Int).SetUint64(amount), // Our initial balance.
            big.NewInt(0),                  // Peer's initial balance.
        })

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

        // Send the proposal.
        ch, err := c.perunClient.ProposeChannel(context.TODO(), proposal)
        if err != nil {
            panic(err)
        }

        return *newPaymentChannel(ch)
    }




We use `OpenChannel()` for opening a Channel, which takes the opponents' address as an argument.
In our example, we say that Alice and Bob both start with a balance of 10 ETH.
According to this, we set the initial allocation of the Channel with `channel.Allocation{}`.
This defines our asset type and how much of this asset will be allocated to the participants at the start (therefore, how much each participant needs to deposit to use the Channel), which sum implies the amount of ETH that must be available in the Channel at any point of time.
Further, we define the `peers`, which are the channel participants' wire addresses (transport layer).

Next, we generate the Channel proposal that includes the `challengeDuration`, a timeframe in which the proposal can be accepted (in our case, 10 seconds),
the Client's address, the channel allocation `initBals`, and our `peers`.

Then we send the proposal with `.ProposeChannel(ctx, proposal)`.
`ctx` is used to abort if the proposal is not accepted in time.
Ultimately, a watcher that listens for events on the potential new Channel is started via `HandleNewChannel()`, which we will look at later in this section.

.. code-block:: go

    func (c *Client) OpenChannel(opponent wallet.Address) error {
        fmt.Printf("%s: Opening channel from %s to %s\n", c.RoleAsString(), c.RoleAsString(), c.OpponentRoleAsString())

        initBal := eth.EthToWei(big.NewFloat(10))

        initBals := &channel.Allocation{
            Assets:   []channel.Asset{ethwallet.AsWalletAddr(c.AssetHolderAddr)},
            Balances: [][]*big.Int{{initBal, initBal}},
        }

        peers := []wire.Address{c.PerunClient.Account.Address(), opponent}

        // Prepare the proposal by defining the channel parameters.
        proposal, err := client.NewLedgerChannelProposal(10, c.PerunAddress(), initBals, peers)
        if err != nil {
            return fmt.Errorf("creating channel proposal: %w", err)
        }
        ctx, cancel := c.defaultContextWithTimeout()
        defer cancel()

        // Send the proposal.
        ch, err := c.PerunClient.StateChClient.ProposeChannel(ctx, proposal)
        c.Channel = ch

        if err != nil {
            return fmt.Errorf("proposing channel: %w", err)
        }

        // Start the on-chain watcher to listen for events
        c.HandleNewChannel(ch) // TODO: 2/2 Check with MG why this is needed here (and not needed in App Channel example)

        fmt.Printf("\n 🎉 Opened channel with id 0x%x \n\n", ch.ID())
        return nil
    }



.. toctree::
   :hidden: