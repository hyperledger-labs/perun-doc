.. SPDX-FileCopyrightText: 2020 Hyperledger
   SPDX-License-Identifier: CC-BY-4.0

.. image:: images/perun_logo.svg
   :width: 300
   :alt: Perun Logo
   :align: center

|

The Perun Framework
===================

The Perun Framework is a modular framework for building blockchain-agnostic payment and state channel applications.
It is an implementation of the `Perun protocols <https://perun.network/wp-content/uploads/Perun2.0.pdf>`_ and provides payment and general state channel functionality for blockchain as well as classical transaction backends.
As a scalability solution, payment and state channels reduce transaction cost and latency by executing transactions directly from peer to peer.
The Perun protocols are proven cryptographically secure and the framework is designed with interoperability in mind.

Contributors & Funding
----------------------
The project originates from a collaboration between the `Chair of Applied Cryptography <https://www.informatik.tu-darmstadt.de/cac/cac/index.en.jsp>`_ of TU Darmstadt and `Bosch Research <https://www.bosch.com/research/>`_.
It joined Hyperledger Labs in 2020 and is currently maintained by a group of dedicated hackers at `PolyCrypt <https://polycry.pt/>`_ and Bosch.

The project receives or has received funding from the German Federal Ministry of Education and Research (BMBF) through the StartUpSecure grants program, the German Science Foundation (DFG), the Foundation for Polish Science (FNP), and the Ethereum Foundation.

Table of contents
-----------------
.. toctree::
   :maxdepth: 2

   introduction
   concepts/state-channel
   concepts/protocols
   go-perun/index
   node/index
