.. SPDX-FileCopyrightText: 2020 Hyperledger
   SPDX-License-Identifier: CC-BY-4.0

##########
Perun-node
##########

Introduction
============

Perun-node is a multi-user node software intended to provide users to open,
transact on and settle state channels. It is implemented in golang and
currently supports payment channels on ethereum. Running an instance of
perun-node will start also start an API server, that serves APIs for the user
to interact with the node.

It uses the go-perun SDK for running the perun protocol and implements the
following functionalities on top of that.

Functionalities
---------------

Off-Chain Identity Management
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Enable the user to identify participants in the off-chain network by using an
Identity provider service. Currently, we have implemented a local identity
provider by storing a list of known participants and their identities in a file
on the disk. The user can aliases to reference the identities of off-chain
participants.

Key Management
^^^^^^^^^^^^^^

Enable the user to manage his cryptographic keys used for signing on-chain
transactions and off-chain messages. Currently we have implemented support for
ethereum keystore.

Session
^^^^^^^

Provide an environment for the user access his ID provider, key manager and
manage all the channels, throughout their lifecycle. In the context of a
session, he/she can open a state channel, do some transactions through channels
and settle the channel. Each session runs its own instance of state channel
network client, ID provider, key manager; and hence provides a complete
isolated environment within the node. It is this feature that enables multiple
users to use the same node by having dedicated sessions for each of them.

User need not be worried about losing his/her data when a sudden closure of
session occurs due to some network error or because of some other reasons.  All
the data within the sessions are continuously persisted. User can reopen the
session at any time. User can close the session according to his/her needs. 

User API
^^^^^^^^

Provide an interface for the user to interact with the node. The UserAPI
consists of three category of methods: Node, Session and Channel to access the
respective functionalities. Currently, we implement two party payment channel
API for ethereum blockchain using gRPC protocol. It can be used for opening a
payment channel where they can send or receive payments and finalize and settle
the channel on the blockchain.

Starting the perun-node will a run a grpc server and client for communication.
Each API used in the system and it's specifications is available at the below
link.

Link to API specification: https://github.com/hyperledger-labs/perun-proposals/blob/master/design/001-RPC-Interface-Specification.md

Perun-node cli
==============

Perun-nodecli is a single user software with an interactive CLI interface to
connect with and use a running instance of perun-node. It is an independant
module that uses gRPC client stubs generated from the API specification to
interact with perun-node and does not share any code with other components of
the project. It provides different set of commands usch as `chain`, `node`,
`session`, `peer-id`, `channel` and `payment`. See the :ref:`User Guide` for
information on how to use these commands.

For steps to build the perun-node, perun-node cli, see the `README
<https://github.com/hyperledger-labs/perun-node/blob/develop/README.md>`_
file.

For trying out off-chain payment using perun-node and perun-node cli see this tutorial: https://github.com/hyperledger-labs/perun-node/blob/develop/cmd/perunnodecli/TryingItOut.md

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
found in the `releases
section <https://github.com/hyperledger-labs/perun-node/releases>`_ of
perun-node repository.
