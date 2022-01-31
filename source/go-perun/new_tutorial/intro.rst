.. _Getting Started:

Introduction
=======================

In this tutorial, we want to take a look at the process of creating a simple application that allows Alice and Bob to open a go-perun channel and use it for performing payment transactions off-chain.
We will cover the introductory functionality go-perun offers for this simple use case.
The presented implementation can be used as an example that helps you build your own channel application.

Dependencies
-------------
Before we start, let us cover the dependencies required for following this tutorial:

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

    KEY_DEPLOYER=0x79ea8f62d97bc0591a4224c1725fca6b00de5b2cea286fe2e0bb35c5e76be46e
    KEY_ALICE=0x1af2e950272dd403de7a5760d41c6e44d92b6d02797e51810795ff03cc2cda4f
    KEY_BOB=0xf63d7d8e930bccd74e93cf5662fde2c28fd8be95edb70c73f1bdd863d07f412e
    BALANCE=100

    ganache-cli --host 127.0.0.1 --port 8545 --account $KEY_DEPLOYER,$BALANCE --account $KEY_ALICE,$BALANCE --account $KEY_BOB,$BALANCE --blockTime=5 --gasPrice=0

.. warning::
   Always keep your private keys private. Do not use the keys of our example with real funds.

.. toctree::
   :hidden:

   client/index
   main/index