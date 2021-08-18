.. SPDX-FileCopyrightText: 2021 Hyperledger
   SPDX-License-Identifier: CC-BY-4.0

Channel app
===========

Channels can optionally have an app. The app describes the rules for updating
the channel state and for interpreting the channel data. No app is required
for payment channels.

An app consists of two parts:

1. **App backed in the perun client**: To validate each off-chain transaction
   during the transact phase.

2. **App smart contract on the blockchain**: To validate each force-update
   transaction during the finalize phase.

To use an app in a channel,

1. The app smart contract corresponding to the app must be deployed on the
   blockchain and referenced at the time of channel proposal and,

2. The app backend must be supported by the perun clients of all the channel
   participants.

In the next section, protocols for each of the four phases in the life cycle of
a state channel are described.

.. note::

    All channel types can have an app. However, the current implementation of
    go-perun supports using apps only in ledger channels and sub-channels.

