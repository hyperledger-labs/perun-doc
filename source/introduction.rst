.. SPDX-FileCopyrightText: 2020 Hyperledger
   SPDX-License-Identifier: CC-BY-4.0

Introduction
=============

Perun
-----

Perun is an off-chain framework which allows users to make transactions without interacting with the blockchain. The main objective of the project is to make the blockchains ready for mass adoption and alleviate current technical challenges such as high fees, latency and low transaction throughput. Perun protocol can be used on top of any blockchain system to accelerate decentralized applications and lower transaction fees.
The Perun Hyperledger Labs project is between Robert Bosch GmbH’s “Economy of Things” project and the Perun team of Technical University of Darmstadt (TUDa) and the project is based on the research work by cryptography researchers from TUDa and University of Warsaw.

`Perun network <https://perun.network/>`_


The perun protocol
------------------

The Perun protocol allows users to shift transaction and smart contract execution away from the blockchain into so-called payment and state-channels. These channels are created by locking coins on the blockchain and can be updated directly between the users and without any on-chain interaction. This makes state-channel-based transactions much faster and cheaper than on-chain transactions. The underlying blockchain guarantees that all off-chain transactions will be enforced on-chain eventually. In comparison to other channel technologies like the Lightning Network, the Perun construction offers the following unique features:

Perun’s state-channel virtualization
````````````````````````````````````
To connect users that do not have a joint open state-channel, existing state-channels can be composed to form so-called virtual channels. These virtual channels are created and closed off-chain over the state-channel network intermediaries. Once opened, the virtual channel is updated directly off-chain between the two connected end users. State-channel virtualization is a concept which is yet to be implemented.

.. image:: ./images/introduction/perun_protocol_overview.svg
  :align: Center
  :alt: Image not available

Blockchain-agnostic
```````````````````
Its modular design enables the flexible integration of Perun’s state-channel technology into any Blockchain or traditional ledger system. 

Interoperability
````````````````
The blockchain agnostic design and state-channel virtualization enable transaction and smart contract execution even across different blockchains (cross-chain functionality). The components such as logging, messaging and persistence are designed in a way that all the features can be customized for some particular use cases.


High security
`````````````
The Perun protocol specifications have been mathematically proven using the latest methods of security research.

The Perun protocol can be used for a wide range of applications in different areas such as finance/FinTech, mobility, energy, e-commerce, telecommunication and any other use case where direct microtransactions are needed.

You can find `Perun <https://ieeexplore.ieee.org/document/8835315>`_ `publications <https://dl.acm.org/doi/10.1145/3243734.3243856>`_ `here <https://www.springerprofessional.de/en/multi-party-virtual-state-channels/16720256>`_.

The Hyperledger Labs Project
----------------------------

As a first step, we are developing a secure and efficient standalone payment application within the Perun Hyperledger Labs project. The labs project currently consists of the following main parts that together form the Perun Framework.

.. image:: ./images/introduction/perun_framework.svg
  :align: Center
  :alt: Image not available

perun-eth-contracts
```````````````````
This provides the Ethereum smart contracts required for implementing the Perun protocol.

Link to the project on GitHub: https://github.com/hyperledger-labs/perun-eth-contracts

go-perun
`````````
An SDK that implements core components of the Perun protocol (state-channel proposal protocol, the state machine that supports persistence and a watcher) and an Ethereum blockchain connector. It is designed to be blockchain agnostic.

Link to the project on GitHub: https://github.com/hyperledger-labs/go-perun

perun-node
``````````
perun-node is a multiuser node which provides a common interface for using state channels. Perun-node generally aims to execute perun protocol by implementing key management, user API, peer ID provider and user session on top of state channel client implemented by go-perun. You can use perun-node to open, transact, settle and close state channels.

Link to the project on GitHub: https://github.com/hyperledger-labs/perun-node

Current functionalities available
`````````````````````````````````
   1. Two party direct payment channels on ethereum

   2. Fully generalized state channel functionality

   3. Command line interface

   4. Channel persistence and restoring

   5. Sub-channels for locking funds to a specific channel application

Features on Roadmap
```````````````````
   1. Virtual channels 

   2. SSI integration with Hyperledger Aries

   3. Additional blockchain backends

   4. Cross-chain channels