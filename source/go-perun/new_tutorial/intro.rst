.. _Getting Started:

Introduction
=======================

This tutorial is split up in 5 sections:

#. Introduction
#. :ref:`Contracts <hl-contracts>`
#. :ref:`Client <client-index>`
#. :ref:`Contract Deployment <lv-contract-deployment>`
#. :ref:`Run Example <setup-the-app>`

We suggest you to go through them in chronological order.
Before we start, let us have a look on what you need to have installed on your system to follow this tutorial.

Dependencies
-------------

Tutorial Source Code
~~~~~~~~~~~~~~~~~~~~

To make it easier to follow the tutorial, you may already clone the source code repository:

.. code-block:: bash

   cd $GOPATH/src
   git clone https://github.com/perun-network/perun-examples.git
   cd perun-examples/payment-channel
   # Initialize Golang
   go mod tidy

Running the code is the :ref:`last part <run-the-app>`, but feel free to try it out first.

Golang
~~~~~~~~~~~~~~~~~~~~

The tutorial source code will be written in `Golang`.
The official `Golang` installation guide can be found `here <https://golang.org/doc/install>`_.
Restart your shell and check the installation by running::

   go version

Ganache CLI
~~~~~~~~~~~~~~~~~~~~

For the purpose of this tutorial we will use `ganache-cli <https://github.com/trufflesuite/ganache>`_ for providing us with a local Ethereum blockchain for testing our application locally.
Install ganache-cli by following `the instructions on the web page <https://github.com/trufflesuite/ganache#getting-started>`_.
You can check if ganache-cli is installed by running::

   ganache-cli --version

When we run our local blockchain, we usually configure accounts that we want to prefund.
We will do this by specifying private keys.
For the purpose of this tutorial we will use the following ganache-cli command::

    ganache-cli --host 127.0.0.1 --port 8545 --account 0x1af2e950272dd403de7a5760d41c6e44d92b6d02797e51810795ff03cc2cda4f,100000000000000000000 --account 0xf63d7d8e930bccd74e93cf5662fde2c28fd8be95edb70c73f1bdd863d07f412e,100000000000000000000 --blockTime=1

.. warning::
   Always keep your private keys private. Do not use the keys of our example with real funds.

.. toctree::
   :hidden:

   contracts/contracts
   client/index
   contracts/deploycontracts
   run/index