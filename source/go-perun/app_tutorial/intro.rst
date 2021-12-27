Introduction
============

Usually, decentralized applications (dApps) are deployed as smart contracts, e.g., on the Ethereum blockchain.
On-chain interaction with these can be pretty expensive.
Even more costly than simple payment transactions because usually app-associated data is required.
But their use case is vast because dApps define application-specific state transformations and win conditions that protect against fraudulent behavior (if the dApp is implemented correctly, of course).

In this tutorial, we want to look at the process of using go-perun, similar to the payment channels, for so-called "app channels" to perform interactions with a Tic-Tac-Toe dApp off-chain (therefore, cheap and fast).
These app channels are more advanced than the previous payment channel example but are based on many of the same concepts and, therefore, we can reuse parts of the implementation.
It is recommended to have a look at the :ref:`payment channel example <Getting Started>` first before continuing.

The source code of this tutorial is available on `GitHub <https://github.com/perun-network/perun-examples/tree/master/app-channel>`_.

Dependencies
-------------
The dependencies remain unchanged from the previous tutorial.
Follow :ref:`the description here <payment-channel-dependencies>` if you did not already do so.

Additionally, a basic knowledge of `Solidity <https://docs.soliditylang.org/en/latest/>`__ will be needed for parts of the tutorial.

Objective
---------
The setup is similar to the format before.
Alice and Bob have an on-chain connection to an Ethereum blockchain and a direct link to each other for operating their app-channel.
They decided to play Tic-Tac-Toe for a certain amount of money.
The parties can make alternating moves until one party wins.
The winning party is rewarded with the funds the opposite party put into the app channel.