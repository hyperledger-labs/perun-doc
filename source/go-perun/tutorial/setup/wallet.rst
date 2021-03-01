Wallet
======

We will setup a wallet to hold the *accounts*.
As simplification we use the same *mnemonic* for both *roles*.
In a real program you would choose one *mnemonic* per *role*.

.. note::
   A *mnemonic* is an alternative representation of an *Ethereum* secret key.

HD Wallet
---------

Setting up the wallet consists of parsing the *mnemonic*, deriving a wallet from it and deriving accounts from that wallet.  
To structure our program, we introduce a *setupWallet* function that will do these three steps. Thanks to `miguelmota's`_ *mnemonic* parser it looks like this:

.. literalinclude:: ../../../perun-examples/simple-client/wallet.go
   :language: go
   :lines: 16-33

We pass the *role* to the function since we need to create one account for each *role*.
The third argument to `NewWallet`_ defines the index of the first account that will be later on created with `NewAccount`_. *Alice* will have the first account (index 0) and *Bob* the second (index 1).
The `"m/44'/60'/0'/0/0"` argument defines the *derivation path*. We just use the default value here.

.. note::
   | The *derivation path* gives the **HD** wallet its name by specifying the location of an account in a **H**\ ierarchical and **D**\ eterministic way.
   | *Ethereum* HD wallets normally use `m/44'/60'/0'/0/0`.

These *accounts* will be used throughout the code to sign on- and off-chain transactions.
You could create multiple *accounts* to keep on- and off-chain *accounts* separate.

.. note::
  | These are the same *accounts* that you would get when entering the *mnemonic* into *MetaMask*.

HD Transactor
-------------

Signing transactions is quite a complex thing in *Ethereum*. *go-perun* abstracts most of it away but we still have to deal with the remnants.
*Ethereum* has multiple (currently three) different transaction signature algorithms.
*go-perun* exposes this functionality to the user but in our case, it is enough to use the *EIP155* signature algorithm and *1337* as *chain id*.
We will need this `Transactor` in the next step:

.. literalinclude:: ../../../perun-examples/simple-client/wallet.go
   :language: go
   :lines: 35-39

.. note::
   | A signature is only valid on a blockchain with the same *chain id*.
   | One use case is to prevent *Ethereum Classic* transactions from being used on the *ETH* main chain.

.. _miguelmota's: https://github.com/miguelmota/go-ethereum-hdwallet
.. _NewWallet: https://pkg.go.dev/perun.network/go-perun/backend/ethereum/wallet/hd#NewWallet
.. _NewAccount: https://pkg.go.dev/perun.network/go-perun/backend/ethereum/wallet/hd#Wallet.NewAccount
