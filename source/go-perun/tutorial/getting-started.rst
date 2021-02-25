.. _Getting Started:

Getting Started
===============

First we setup some dependencies: Golang and ganache-cli. But no worries, we will walk you through it 😌

Tutorial Source Code
--------------------

To make it easier to follow the tutorial, you may already clone the source code repository:

.. code-block:: bash
   
   cd $GOPATH/src
   git clone https://github.com/perun-network/perun-tutorial.git
   cd perun-tutorial/go-perun-test
   # Initialize Golang
   go mod tidy

Running the code is the :ref:`last part <run-the-app>`, but feel free to try it out first.

Golang
------

The tutorial source code will be written in *Golang*.
The official *Golang* installation guide can be found `here <https://golang.org/doc/install>`_.
Restart your shell and check the installation by running::

   go version

Ganache CLI
-----------

For the purpose of this tutorial we will use `ganache-cli <https://github.com/trufflesuite/ganache-cli>`_ for providing us with a local Ethereum blockchain for testing our application locally.
Install ganache-cli by following `the instructions on the web page <https://github.com/trufflesuite/ganache-cli#installation>`_.
You can check if ganache-cli is installed by running::

   ganache-cli --version

When we run our local blockchain, we usually configure accounts that we want to prefund.
We will do this by specifying a mnemonic.
A mnemonic is a sequence of randomly chosen words from which account secret keys can be derived.
For the purpose of this tutorial we will use the following mnemonic::

   "pistol kiwi shrug future ozone ostrich match remove crucial oblige cream critic"

.. warning::
   Always keep your *mnemonic* private. Do not use the example *mnemonic*
   with real funds.


