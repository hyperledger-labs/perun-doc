Client
======
The app channel's client is similar to before, and we can reuse (with slight changes) a lot of the previous :ref:`payment channel client <client>` logic.
Most notably, the client is the place where we implement the channel opening/proposing functionality.

Implementation
~~~~~~~~~~~~~~
We put the following code in `client/client.go`.

.. note::

    Again, we will use `context.TODO()` and `panic(err)` to keep the code simple. In production code, one should always use proper context and handle errors appropriately.


Structure
---------
The structure of the `AppClient` is similar to the one of the `PaymentClient`.
The `perunClient`, `account`, `currency` and `channels` remain the same.

What is added is `stake` and `app`:

- `stake` sets the amount of the given asset the client is willing to put into the app channel.
- `app` includes an instance of the app that the client wants to use. We will look at the implementation of `app.TicTacToeApp` at a later state here. # TODO: Reference

.. code-block:: go
    :emphasize-lines: 6,7

    // AppClient is a payment channel client.
    type AppClient struct {
        perunClient *client.Client    // The core Perun client.
        account     wallet.Address    // The account we use for on-chain and off-chain transactions.
        currency    channel.Asset     // The currency we expect to get paid in.
        stake       channel.Bal       // The amount we put at stake.
        app         *app.TicTacToeApp // The app definition.
        channels    chan *AppChannel
    }

Constructor
-----------
The constructor is extended accordingly with the two attributes `stake` and `app`.
There are no relevant changes to the `PaymentClient`'s constructor. Therefore, the additional lines of code are only marked here.
For explanation of the logic, please look at :ref:`this description <client-constructor>`.

.. code-block:: go
    :emphasize-lines: 10,11,56,57

    // SetupAppClient creates a new payment client.
    func SetupAppClient(
        bus wire.Bus,
        w *swallet.Wallet,
        acc common.Address,
        nodeURL string,
        chainID uint64,
        adjudicator common.Address,
        asset ethwallet.Address,
        app *app.TicTacToeApp,
        stake channel.Bal,
    ) (*AppClient, error) {
        // Create Ethereum client and contract backend.
        cb, err := CreateContractBackend(nodeURL, chainID, w)
        if err != nil {
            return nil, fmt.Errorf("creating contract backend: %w", err)
        }

        // Validate contracts.
        err = ethchannel.ValidateAdjudicator(context.TODO(), cb, adjudicator)
        if err != nil {
            return nil, fmt.Errorf("validating adjudicator: %w", err)
        }
        err = ethchannel.ValidateAssetHolderETH(context.TODO(), cb, common.Address(asset), adjudicator)
        if err != nil {
            return nil, fmt.Errorf("validating adjudicator: %w", err)
        }

        // Setup funder.
        funder := ethchannel.NewFunder(cb)
        dep := ethchannel.NewETHDepositor()
        ethAcc := accounts.Account{Address: acc}
        funder.RegisterAsset(asset, dep, ethAcc)

        // Setup adjudicator.
        adj := ethchannel.NewAdjudicator(cb, adjudicator, acc, ethAcc)

        // Setup dispute watcher.
        watcher, err := local.NewWatcher(adj)
        if err != nil {
            return nil, fmt.Errorf("intializing watcher: %w", err)
        }

        // Setup Perun client.
        waddr := ethwallet.AsWalletAddr(acc)
        perunClient, err := client.New(waddr, bus, funder, adj, w, watcher)
        if err != nil {
            return nil, errors.WithMessage(err, "creating client")
        }

        // Create client and start request handler.
        c := &AppClient{
            perunClient: perunClient,
            account:     waddr,
            currency:    &asset,
            stake:       stake,
            app:         app,
            channels:    make(chan *AppChannel, 1),
        }
        go perunClient.Handle(c, c)

        return c, nil
    }


Open/Propose Channel
--------------------
In the channel opening procedure `OpenAppChannel()`, we need to perform two changes to adapt to our app channel use case.
For an explanation of the remaining logic, please look at :ref:`this description <client-propose-channel>`.

On the one hand, we now expect both parties to deposit matching funds to ensure equal awards for the winner.
Notice how this was not a requirement in the payment channel before.
We realize this by putting `stake` for both `[]channel.Bal` indices when calling `Allocation.SetAssetBalances()`.

.. code-block:: go
    :emphasize-lines: 7-10

    // OpenAppChannel opens a new app channel with the specified peer.
    func (c *AppClient) OpenAppChannel(peer *AppClient) AppChannel {
        participants := []wire.Address{c.account, peer.account}

        // We create an initial allocation which defines the starting balances.
        initAlloc := channel.NewAllocation(2, c.currency)
        initAlloc.SetAssetBalances(c.currency, []channel.Bal{
            c.stake, // Our initial balance.
            c.stake, // Peer's initial balance.
        })

On the other hand, we include our application `app` in the channel proposal.
We call `client.WithApp()` provided by go-perun, configuring the given `app` with the desired initial data.
How `app.InitData()` generates the initial data we will discuss in the app section. # TODO: Add ref

Please keep in mind the importance of the :ref:`challenge duration <challenge_duration_warning>` parameter.
It is especially meaningful in the app channel context due to possibly complex state transitions that could take time to evaluate.

.. code-block:: go
    :emphasize-lines: 4, 5, 12

        // Prepare the channel proposal by defining the channel parameters.
        challengeDuration := uint64(10) // On-chain challenge duration in seconds.

        firstActorIdx := channel.Index(0) // TODO: get idx via go-perun with 0.9.0
        withApp := client.WithApp(c.app, c.app.InitData(firstActorIdx))

        proposal, err := client.NewLedgerChannelProposal(
            challengeDuration,
            c.account,
            initAlloc,
            participants,
            withApp,
        )
        if err != nil {
            panic(err)
        }

        // Send the app proposal
        ch, err := c.perunClient.ProposeChannel(context.TODO(), proposal)
        if err != nil {
            panic(err)
        }

        // Start the on-chain event watcher. It automatically handles disputes.
        c.startWatching(ch)

        return *newAppChannel(ch)
    }

Utilities
~~~~~~~~~
The utility functions `startWatching()`, `AcceptedChannel()`, `Shutdown()`, `CreateContractBackend()`, `EthToWei()` and `WeiToEth()` remain untouched and are are taken over from their :ref:`previous definitions <client-utility>` in the payment channel tutorial.
These functionalities are implemented in `client/client.go` and `client/util.go`.


.. toctree::
   :hidden:


