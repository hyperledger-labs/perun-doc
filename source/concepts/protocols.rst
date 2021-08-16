.. SPDX-FileCopyrightText: 2021 Hyperledger
   SPDX-License-Identifier: CC-BY-4.0

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

Types of state channels
=======================

Perun protocols support three types of channels:

1. Ledger channel.
2. Sub-channel.
3. Virtual channel.

Life cycle for each of these channels consist of the same phases described
above. The differences are in, how the channels are funded during the ``open
phase`` and how the funds are withdrawn during the ``withdraw phase``. This
layer, where funds will be deposited / channels will be settled, will be
referred to as ``parent layer`` in the further discussions.

Ledger channel
--------------

   - Formed between any two parties having sufficient funds in their on-chain
     accounts.
   - The funds are directly deposited into the smart contracts on the
     blockchain.
   - Allows any number of off-chain transactions between the participants.
   - The channel must be settled on the blockchain.

Sub-channel
-----------

   - Formed between participants who have a ledger channel established between
     them.
   - Funds for the sub-channel are locked on the ledger channel. Hence, a
     sub-channel can be setup without any interaction with the blockchain.
   - Sub-Channel is settled,

     - by an off-chain update on the parent ledger channel, if both the
       participants agree on the final state of the sub-channel.
     - by registering a dispute on the blockchain and resolving it, otherwise.
       In this case, the parent channel and all other sub-channels opened using
       the parent channel will also be settled on the blockchain.

Virtual channel
---------------

   - Formed between two participants who do not have a ledger channel
     established between them, but each of them has a ledger
     channel established with a common intermediary.
   - Funds are locked in the two ledger channels that the participants have
     with the common intermediary. Hence, a virtual channel can be setup
     without any interaction with the blockchain.
   - Virtual channel is settled,

     - by an off-chain update on each of the two parent ledger channels, if
       both the participants agree on the final state of the virtual channel.
     - by registering a dispute on the blockchain and resolving it, otherwise.
       In this case, either one or both of the parent channels and all
       other sub-channels, virtual channels opened using them will also be
       finalized on the blockchain.

.. note:

   From the above descriptions, it can be seen that sub-channels and virtual
   channels require **zero on-chain** interactions under normal circumstances.
   On-chain interactions are required only when the participants do not agree on
   the state to be settled.



**Channel app**:

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

.. toctree::
   :hidden:

   protocols_phases
