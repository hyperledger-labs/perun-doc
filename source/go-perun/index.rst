Go-Perun
========

`Go-Perun <https://github.com/hyperledger-labs/go-perun>`_ is an open-source library for building state channel applications on top of almost any transaction backend.
It is designed with modularity in mind.

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


Developer Tutorial
------------------

The :ref:`developer-tutorial` shows how go-perun is used to build a simple scalable payment application on top of the Ethereum blockchain.

.. toctree::
   :maxdepth: 2

   tutorial/index


Security Disclaimer
-------------------

This software is still under development.
The authors take no responsibility for any loss of digital assets or other damage caused by the use of it.

Copyright
---------

Copyright 2021 - PolyCrypt GmbH, Germany.
Use of the source code is governed by the Apache 2.0 license that can be found in the `LICENSE file <https://github.com/hyperledger-labs/go-perun/blob/dev/LICENSE>`_.

Feedback & Contact
------------------

Feel free to provide your feedback on the library via `our GitHub page <https://github.com/hyperledger-labs/go-perun>`_. For business inquiries you can contact us at `info@perun.network <mailto:info@perun.network>`_.

Funding & Additional Information
--------------------------------

The project is supported by the German Federal Ministry of Education and Research (BMBF) through the StartUpSecure grants program as well as the German Science Foundation (DFG), the Foundation for Polish Science (FNP), and the Ethereum Foundation.

More information can be found at `<https://perun.network/>`_.

Related projects:

* `Perun CLI Demo <https://github.com/perun-network/perun-eth-demo>`_
* `Perun Node <https://github.com/hyperledger-labs/perun-node>`_
