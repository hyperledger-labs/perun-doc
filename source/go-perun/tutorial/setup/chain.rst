Chain Connection
================

For blockchain communication we need an `ethclient.Client` and a `ContractBackend`.
The `ethclient.Client` is the communicator on which the `ContractBackend` is built for *go-perun* to interact with the on-chain contracts.
You can create an `ethclient.Client` by calling `ethclient.Dial` with the *URL* of the node to connect.
The `ContractBackend` is constructed from the `ethclient.Client` in combination with the `Transactor` from the previous step:

.. literalinclude:: ../go-perun-test/onchain.go
   :language: go
   :lines: 19-27

.. note::
   | You can dial any RPC Ethereum node here, even an *Infura* endpoint.
