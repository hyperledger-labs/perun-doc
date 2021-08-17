.. SPDX-FileCopyrightText: 2021 Hyperledger
   SPDX-License-Identifier: CC-BY-4.0

Channel app
===========

Channels can optionally have an app. The app describes the rules for updating
the channel state and for interpretting the channel data. No app is required
for payment channels.

An app consists of two parts: a smart contract and support for it the go-perun
client.

In the next section, protocols for each of the four phases in the life cycle of
a state channel are described.

.. note::

    All channel types can have an app. However, the current implementation of
    go-perun supports using apps only in ledger channels and sub-channels.
