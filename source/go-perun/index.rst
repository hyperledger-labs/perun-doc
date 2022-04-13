Go-Perun
========

`Go-Perun <https://github.com/hyperledger-labs/go-perun>`_ is an open-source library for building state channel applications on top of almost any transaction backend.
It is designed with modularity in mind.

Project info
------------

**Disclaimer.**
This software is still under development.
The authors take no responsibility for any loss of digital assets or other damage caused by the use of it.


**Funding.**
The project is supported by the German Federal Ministry of Education and Research (BMBF) through the StartUpSecure grants program as well as the German Science Foundation (DFG), the Foundation for Polish Science (FNP), and the Ethereum Foundation.


**Contact.**
Feel free to provide your feedback on the library via `our GitHub page <https://github.com/hyperledger-labs/go-perun>`_. For business inquiries you can contact us at `info@perun.network <mailto:info@perun.network>`_. More information can be found at `<https://perun.network/>`_.


Architecture
------------

**Abstract interfaces.** At the core of the library is the client package which represents the fundamental protocols. A client interacts with its environment through abstract interfaces.

* The transaction backend is represented by package wallet, which represents account logic and package channel, which provides the core data structures of a channel.
* The peer-to-peer communication layer is represented by package wire.
* Data persistence is provided through package channel/persistence.
* Logging is provided through the package log.

.. image:: ../images/go-perun/goperun_architecture.png
   :width: 400
   :alt: Architecture of go-perun

**Instantiation depending on the application context.** When building an application, the abstract interfaces are instantiated with concrete implementations depending on the application context.
By default, the library ships with an Ethereum adapter as the transaction backend, a TCP/IP adapter for client communication, a LevelDB adapter for data persistence, and a Logrus adapter for logging.


Tutorials
---------

Payment Channels
~~~~~~~~~~~~~~~~
In the :ref:`payment channel tutorial <payment_tutorial_intro>`, you will learn how to build a simple payment channel application that uses Perun channels for realizing fast and low-fee payment transactions.

.. toctree::
   :maxdepth: 1

   payment_tutorial/intro
   payment_tutorial/client
   payment_tutorial/test

App Channels
~~~~~~~~~~~~
In the :ref:`app channel tutorial <app_tutorial_intro>`, we guide you through the process of creating an app channel application where two players trustlessly play an interactive game with blockchain tokens at stake.

.. toctree::
   :maxdepth: 1

   app_tutorial/intro
   app_tutorial/app/app_intro
   app_tutorial/client
   app_tutorial/test

Blockchain Migration
~~~~~~~~~~~~~~~~~~~~
In the :ref:`migration tutorial<payment_client_on_polkadot>`, you will learn how to migrate the payment channel client from Ethereum to Polkadot.

.. toctree::
   :maxdepth: 1

   port_eth_dot/migration
