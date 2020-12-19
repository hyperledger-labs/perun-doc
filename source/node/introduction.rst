.. SPDX-FileCopyrightText: 2020 Hyperledger
   SPDX-License-Identifier: CC-BY-4.0

Perun-node
===========

The perun-node is multi-user state channel node that can be used for opening,
transacting on and closing state channels. It builds on the state channel
client implemented by go-perun and implements the following functionalities.

Functionalities
---------------

Off-Chain Identity Management
`````````````````````````````
Enable the user to identify participants in the off-chain network by using an
Identity provider service. Currently, we have implemented a local identity
provider by storing a list of known participants and their identities in a file
on the disk. The user can aliases to reference the identities of off-chain
participants.

Key Management
``````````````
Enable the user to manage his cryptographic keys used for signing on-chain
transactions and off-chain messages. Currently we have implemented support for
ethereum keystore.

Session
````````
Provide an environment for the user access his ID provider, key manager and
manage all the channels, throughout their lifecycle. In the context of a session,
he/she can open a state channel, do some transactions through channels and
settle the channel. Each session runs its own instance of state channel network
client, ID provider, key manager; and hence provides a complete isolated
environment within the node. It is this feature that enables multiple users to
use the same node by having dedicated sessions for each of them.

User need not be worried about losing his/her data when a sudden closure of
session occurs due to some network error or because of some other reasons.  All
the data within the sessions are continuously persisted. User can reopen the
session at any time. User can close the session according to his/her needs. 

User APIs
``````````
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
--------------
Perun-nodecli is an interactive CLI program to interact with the running
instance of perun-node. The options available and the pre-requisites we have to
set before running this cli is well explained in the below link.

For steps to build the perun-node, perun-node cli, see the `README
<https://github.com/hyperledger-labs/perun-node/blob/develop/README.md>`_
file.

For trying out off-chain payment using perun-node and perun-node cli see this tutorial: https://github.com/hyperledger-labs/perun-node/blob/develop/cmd/perunnodecli/TryingItOut.md

Releases
--------

v0.1.0 & v0.2.0
````````````````
These are legacy versions of our node development. In the legacy versions, our
project were known in the name 'dst-go'. Currently we are not using it.

v0.3.0
``````
Here project name changed to perun-node from dst-go. This is a
re-implementation of the legacy versions.

Below are the main features included in this version:

   1. Ethereum backend.

   2. Key management using ethereum keystore.

   3. YAML file based ID provider.

   4. Session for enabling multiple users use the same node.

   5. Two party payment channel API over gRPC protocol.

   We use go-perun SDK which implements state channel client based on perun
   protocol. All the above mentioned functionalities build on top of go-perun.

v0.4.0
``````
New features of this release include below functionalities.

   1. perunnode- an executable binary for running an instance of perun node.
   
   2. perunnodecli- an interactive applicaton as reference client implementation for connecting to perun node.

   3. Provide an option to close a session.

   4. Provide persistence support, ie close a session with open channels,  restore it later and make transactions on the restored channel.

   Apart from this features, there are some improvements made on the previous version.

   Improvements done :

      1. Updated go-perun perun dependencies to include below feature.

         1. Channel nonce created using the random numbers from both participants of the channel.

         2. Initialize contract backend using transactor interface.

      2. Updated payment channel API to use consistent data formats.

      3. Combined channel close subscription and channel update subscription into one.
