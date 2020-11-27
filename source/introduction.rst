.. Perun-node documentation master file, created by
   sphinx-quickstart on Thu May 17 17:20:50 2018.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Introduction
=============
Perun-node
-----------
Perun-node is a multiuser node which provides a common interface for using state channels. Perun-node, an open source Hyperledger-labs project provides a 2nd layer scaling solution which will reduce the transaction costs. You can see 2nd layer scaling and state channels explained below.

Link to the project on GitHub: https://github.com/hyperledger-labs/perun-node

2nd Layer Scaling
-----------------
A DLT (Distributed Ledger Technology, e.g. Blockchain) cannot simultaneously provide secure and trustworthy consensus – often achieved via complex and slow operations like Proof of Work (PoW) or Proof of Stake (PoS) algorithms – and high transaction volume and throughput. 

Here 2nd layer protocols come to the rescue: by reducing the number of transactions with the underlying DLT and letting most transactions happen “off-chain”, i.e. directly between peers via so-called state channels, transactions can be scaled both in volume and rate on the second layer while the first layer (DLT) serves as a notary or escrow service providing the necessary security guarantees:

.. image:: ./images/introduction/state_Channels_Overview.svg
  :align: Center
  :alt: Image not available

State Channels
``````````````
State channels are a scalability technology in which the transaction(i.e exchange states) between the users takesplace directly outside of the blockchain or we can say off-chain.

State channels provide an ad-hoc solution for time-constrained problems. As the cost of these transactions via state channels can be near-nil and transaction speed is only limited by the underlying peer-to-peer communications technology, they provide a suitable basis for performing micro-transactions repeatedly over a period of time. Scaling transactions for permanent or long-running problems could be better achieved via other technologies like sidechains.

A state channel protocol can be compared to a pre-paid account,
where some assets are blocked in the beginning,
then the transactions over these assets are performed
and finally the resulting state is published and executed.

Therefore, the lifecycle of a state channel consists of four phases:

1. Open: Publish initial state (block assets)
2. Transact: Exchange states directly
3. Register: Publish final state
4. Close: Execute final state

These four phases are now described in more detail.

Phase 1: Open
^^^^^^^^^^^^^
Locking amount x (e.g. money or assets) from all involved parties, by using a smart contract on the DLT.
This will be the initial state for the further off-chain transactions.

.. image:: ./images/introduction/sc_Workflow_1.svg
  :align: Center
  :alt: Image not available

Phase 2: Transact
^^^^^^^^^^^^^^^^^
In this phase, the parties will exchange transactions in a direct way.
These transactions will modify the initial state
and distribute the blocked assets among the participants.
The agreement to a new state must be approved by all involved parties
and is performed by signing the new state and send it to the other participants.
The order of the states is done by using a version counter.

.. image:: ./images/introduction/sc_Workflow_2.svg
  :align: Center
  :alt: Image not available

Phase 3: Register
^^^^^^^^^^^^^^^^^
After transactions are done and a final state is achieved,
any of the parties can submit the final state to the smart contract.
The published state is validated by the smart contract
by checking if the signatures are corresponding to the included state.
Publishing a state triggers a defined challenge period.
During this time, the other participant of the channel can check
if the published state corresponds to its final state.

.. image:: ./images/introduction/sc_Workflow_3_1.svg
  :align: Center
  :alt: Image not available


In general, there are three options to react:

1. Let the challenge period go to an end if the final state is the same as local. This will preserve transaction cost.
2. Publish the same state, this will be treated as an agreement and the smart contract will execute the final state immediately, before the timeout will reach his end.
3. If the published state does not corresponds to the local final state, this final state can be published. As its version is higher than the other one, this will be executed by the smart contract if the challenge period is still active.

The next picture will show the steps if one of the party tries to update the contract with an older state.

.. image:: ./images/introduction/sc_Workflow_3_2.svg
  :align: Center
  :alt: Image not available  

During the challenge period, the other party can submit the newer state if it has any.

.. image:: ./images/introduction/sc_Workflow_3_3.svg
  :align: Center
  :alt: Image not available

Phase 4: Execute
^^^^^^^^^^^^^^^^
Once the challenge period expires, the final available state will be executed.
In case of blocked money/assets, it will be distributed to the corresponding accounts
based on the published final state the smart contract received.

.. image:: ./images/introduction/sc_Workflow_4.svg
  :align: Center
  :alt: Image not available

Scope of the project
--------------------
go-Perun
````````
Go-perun is the go implementation of perun protocol which is a scalability solution built on top of existing blockchain system. The prime objective of the project is to bring down the transaction cost and increase the system throuput by performing incremental transactions off-chain.

Perun-node
``````````````
Perun-node generally aims to execute perun protocol by implementing key management, user API, peer ID provider and user session on top of state channel client implemented by go-perun. You can use perun-node to open, transact, settle and close a state channels.
