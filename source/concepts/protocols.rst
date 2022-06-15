.. SPDX-FileCopyrightText: 2021 Hyperledger
   SPDX-License-Identifier: CC-BY-4.0

.. _concepts-protocols:

*********
Protocols
*********

The Perun state channel protocols are a set of protocols for setting up state
channels, doing off-chain transactions on these channels and settling them.

The life cycle of a state channel consists of 4 phases:

1. **Open**: Setup up the channel and deposit funds as per the initial balance.
2. **Transact**: Do off-chain transactions.
3. **Finalize**: Agree on the final state of the channel.
4. **Settle**: Reallocate the funds as per the final balance and withdraw them.

The Perun protocol supports different types of channels. The description and protocol
for each of the channel types is explained in the next sections.

A **multi-ledger channel** is a special type of channel whose assets may reside on different ledgers.
The corresponding protocols are discussed in a separate section.

.. toctree::
   :hidden:

   channel_types
   channel_app
   protocols_phases
   protocols_funding_settling
   multi_ledger
