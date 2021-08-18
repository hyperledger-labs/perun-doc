.. SPDX-FileCopyrightText: 2020 Hyperledger
   SPDX-License-Identifier: CC-BY-4.0

.. _node-intro:

Introduction
============

Perun-node is a multi-user node software intended to facilitate users to open,
transact on and settle state channels. It uses the go-perun SDK for running the
perun protocol and implements the other functionalities (described in the
following section) on top of that. The first implementation is done in golang
and currently supports payment channels. Running an instance of perun-node will
start an API server that acts as an interface for the user to interact with the
node.

Functionalities
---------------

Off-Chain Identity Management
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Enable the user to identify participants in the off-chain network by using an
identity provider service. Currently, we have implemented a local identity
provider by storing a list of known participants and their identities in a file
on the disk. An alias is assigned to each participant and these aliases are
unique within an instance of identity provider. The aliases are used by the
user to refer to participants in API calls to the node.

Key Management
^^^^^^^^^^^^^^

Enable the user to manage his cryptographic keys used for signing on-chain
transactions and off-chain messages. Currently we have implemented support for
Ethereum keystore.

Session
^^^^^^^

Provide an environment for the user to access his ID provider, key manager and
all the channels opened within this session. In the context of a session,
he/she can open a state channel, do some transactions on the channels and
settle it. Each session runs its own instance of state channel network client,
ID provider, key manager; and hence provides a complete isolated environment
within the node. It is this feature that enables multiple users to use the same
node by having dedicated sessions for each of them.

User need not be worried about losing his/her data when a sudden closure of
session occurs due to some network error or because of some other reasons. All
the data within the sessions are continuously persisted. User can reopen the
session at any time and the last known state of the session will be restored.
User also has the option to close a session that has open channels by using
``force`` option. In this case as well, the session data is persisted and
restored when the session is reopened.

User API
^^^^^^^^

Provide an interface for the user to interact with the node. The UserAPI
consists of three category of methods: Node, Session and Channel to access the
respective functionalities. Currently, we implement two party payment channel
API for ethereum blockchain using gRPC protocol. It can be used for opening a
payment channel where they can send or receive payments, finalize the channels
on the blockchain, settle it and withdraw the funds back to the user's account.

Starting the perun-node will run a gRPC server for communication. Complete
specification of the payment channel API served by the perun-node can be found
[here](https://github.com/hyperledger-labs/perun-proposals/blob/main/design/001-RPC-Interface-Specification.md).

Perun-node cli
==============

Perun-node cli is a single user software with an interactive command line
interface to connect with and use a running instance of perun-node. It is an
independent module that uses gRPC client stubs generated from the API
specification to interact with perun-node and does not share any code with
other components.

Releases
========

Current version is
`v0.5.0 <https://github.com/hyperledger-labs/perun-node/releases/tag/v0.5.0>`_.

We have made 5 development releases so far. Of these `v0.1.0
<https://github.com/hyperledger-labs/perun-node/releases/tag/v0.1.0>`_ &
`v0.2.0
<https://github.com/hyperledger-labs/perun-node/releases/tag/v0.2.0>`_ are
legacy versions, developed under the project name 'dst-go', source code of
which can be found in `legacy/master
<https://github.com/hyperledger-labs/perun-node/tree/legacy/master>`_ of
perun-node repo.

Details on the new features and improvements included in each release can be
found in the
`releases section <https://github.com/hyperledger-labs/perun-node/releases>`_
of perun-node repository.

A detailed tutorial on how to use the perun-node is presented in the next
section: :ref:`User Guide` section.
