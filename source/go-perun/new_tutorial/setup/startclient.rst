Start the Client
----------------
Let us combine our earlier steps to initialize the `Client` itself.

    #. We create the Perun Client by calling `setupPerunClient` with the `PerunClientConfig`.
    #. Then we load the (already existing!) asset holder with the address given in the config via `assetholdereth.NewAssetHolderETH`.
    #. Next, we create the actual Client from all its pieces. Notice that there is no channel existing yet. Therefore, the respective field is `nil`.
    #. The handler routine is started, which will trigger callbacks concerning channel proposals and update requests. You might wonder why for both arguments (`ProposalHandler`, `UpdateHandler`), the Client itself is given (`.Handle(c, c)`). This is because we implement both interfaces in our Client by providing `HandleProposal()` and `HandleUpdate()`. If you want, you could separate this functionality, of course.
    #. Ultimately the listener routine is started that listens for incoming connections and automatically adds them to the bus.

We return the generated `Client` to conclude this section.

.. code-block:: go

    type ClientConfig struct {
        PerunClientConfig
        ContextTimeout time.Duration
    }

    func StartClient(cfg ClientConfig) (*Client, error) {
        perunClient, err := setupPerunClient(cfg.PerunClientConfig)
        if err != nil {
            return nil, errors.WithMessage(err, "creating perun client")
        }

        ah, err := assetholdereth.NewAssetHolderETH(cfg.AssetHolderAddr, perunClient.ContractBackend)
        if err != nil {
            return nil, errors.WithMessage(err, "loading asset holder")
        }

        c := &Client{
            cfg.Role,
            perunClient,
            cfg.AssetHolderAddr,
            ah,
            cfg.ContextTimeout,
            nil,
        }

        go c.PerunClient.StateChClient.Handle(c, c)
        go c.PerunClient.Bus.Listen(c.PerunClient.Listener)

        return c, nil
    }