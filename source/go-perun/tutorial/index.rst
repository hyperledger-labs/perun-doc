.. _developer-tutorial:

Tutorial
========

This tutorial describes how to build a simple payment channel application on top of Ethereum using `go-perun <https://github.com/hyperledger-labs/go-perun>`_.
The tutorial targets developers familiar with Golang and Ethereum.
The source code snippets within this tutorial are literally included from *perun-examples*, (c) PolyCrypt GmbH 2021, licensed under `Apache-2.0 <https://raw.githubusercontent.com/perun-network/perun-examples/master/LICENSE>`_. The entire source code is available at `GitHub <https://github.com/perun-network/perun-examples>`_.

The picture below gives an overview of the setup.
*Alice* and *Bob* are the payment channel clients.
They have an on-chain connection to an Ethereum blockchain backend for funding and withdrawing assets onto their payment channel.
They also have a direct off-chain connection for operating their payment channel and sending payments without blockchain interaction.

.. image:: ../../images/go-perun/tutorial_setup.png
   :width: 300
   :alt: Components of payment channel application

.. toctree::
   :maxdepth: 1

   getting-started
   setup/index
   channels/index
   together
