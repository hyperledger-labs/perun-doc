.. SPDX-FileCopyrightText: 2020 Hyperledger
   SPDX-License-Identifier: CC-BY-4.0

.. _embedded-intro:

Introduction
============

Perun-rs is a single user, light node for perun protocol intended to run on
bare metal embedded devices. It can facilitate a user to open, transact on and
settle a state channel. It can directly communicate with other perun clients
for off-chain transactions and uses a remote service for on-chain transactions.

It is implemented as a library and includes an example application for STM
Nucleo F4329ZI evaluation board.

The code can be found in this `repository
<https://github.com/hyperledger-labs/perun-rs/tree/perunnode>`_.

The next section shows the steps for using the included example application
with perun-node.


