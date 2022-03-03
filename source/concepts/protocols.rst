.. SPDX-FileCopyrightText: 2021 Hyperledger
   SPDX-License-Identifier: CC-BY-4.0

.. _concepts-protocols:

*********
Protocols
*********

Perun state channel protocols are a set of protocols for setting up a state
channels, doing off-chain transactions on these channels and settling them.

The life cycle of a state channel consists of 4 phases:

1. **Open**: Setup up the channel and deposit funds as per the initial balance.
2. **Transact**: Do off-chain transactions.
3. **Finalize**: Agree on the final state of the channel.
4. **Settle**: Reallocate the funds as per the final balance and withdraw them.

Perun protocol supports different types of channels. Description and protocol
for each of the channel types is explained in the next sections.

.. toctree::
   :hidden:

   channel_types
   channel_app
   protocols_phases
   protocols_funding_settling
