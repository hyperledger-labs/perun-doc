.. dst-doc documentation master file, created by
   sphinx-quickstart on Thu May 17 17:20:50 2018.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to the documentation of Direct State Transfer (DST) !
=============================================================

Direct State Transfer (DST) is an open source project that aims to
increase blockchain transaction throughput by using just a handful of
main chain transactions to move an entire peer-to-peer network of
activity off the main chain. After an initial setup of a set of basic
transaction channels, this network lets any participant transact with
any other participant via virtual channels which do not require
additional on-chain setup. We do this by implementing the Perun
protocol, which has been formally proven to allow for secure off-chain
transactions.

Link to the project on GitHub: https://github.com/direct-state-transfer

Project Status
--------------

A first version of the software was developed in the `dst-go repository
<https://github.com/direct-state-transfer/dst-go>`_ and is now available
in the branch `legacy/master
<https://github.com/direct-state-transfer/dst-go/tree/legacy/master>`__.
It was neither ready for production use nor did it implement the
complete Perun protocol. But with the basic features available it is at
a stage where you could try it out. The corresponding documentation can
be found in branch `legacy/master
<https://github.com/direct-state-transfer/dst-doc/tree/legacy/master>`__
of the `dst-doc repository
<https://github.com/direct-state-transfer/dst-doc>`_.

Now dst-go will be re-implemented from scratch building upon `go-perun
<https://github.com/direct-state-transfer/go-perun>`_, a
blockchain-agnostic state channels framework that implements the `Perun
state channel protocols <https://perun.network/>`_. This is happening on
new master and develop branches both in dst-go and dst-doc.
