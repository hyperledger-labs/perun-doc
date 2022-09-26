.. _multi_ledger_tutorial:

Multi-Ledger Channel Tutorial
-----------------------------

In this tutorial, we will show you how to set up a multi-ledger channel, i.e., a channel that operates between between
multiple (here, 2) chains using go-perun. We will then let two clients, Alice and Bob, transfer ERC20 tokens
from one chain to the other chain in this channel.

We recommend following the  :ref:`payment channel tutorial <payment_tutorial_intro>` first since we will reuse most of
the code but it's not a must as we will also explain the relevant parts in this tutorial.


Source Code
...........
This tutorial's source code is available at `perun-examples/multi-ledger-example <https://github.com/perun-network/perun-examples/tree/master/multi-ledger-example>`_.

.. code-block:: bash

   # Download repository.
   git clone https://github.com/perun-network/perun-examples.git
   cd perun-examples/multi-ledger-example


Client Setup
............
First, we will have a look how we initialize the client in order to use multi-ledger channels.
For that, navigate into ``client/client.go``.

There, we added a struct for holding all relevant information about the chains we want to use:

.. literalinclude:: ../../perun-examples/multiledger-channel/client/client.go
   :caption: `👇 This code on GitHub. <https://github.com/hyperledger-labs/go-perun/blob/e831f7ec3d1fee283cc66a3035969a2c7b9aad71/channel/multi/funder.go#L26>`__
   :language: go
   :lines: 45-52

The ``PaymentClient`` from the payment channel tutorial is extended such that it holds an array of two currencies
for the two chains instead of only one.

.. literalinclude:: ../../perun-examples/multiledger-channel/client/client.go
   :caption: `👇 This code on GitHub. <https://github.com/hyperledger-labs/go-perun/blob/e831f7ec3d1fee283cc66a3035969a2c7b9aad71/channel/multi/funder.go#L26>`__
   :language: go
   :lines: 54-60


Now, we are ready to create the constructor for our ``PaymentClient``, which takes a number of parameters as described
below. Note that the last one is the array of the two chains that we want to use.

.. literalinclude:: ../../perun-examples/multiledger-channel/client/client.go
   :caption: `👇 This code on GitHub. <https://github.com/hyperledger-labs/go-perun/blob/e831f7ec3d1fee283cc66a3035969a2c7b9aad71/channel/multi/funder.go#L26>`__
   :language: go
   :lines: 62-68

The initialization of the Perun client is similar as in the payment channel tutorial,
however, here we will highlight the differences regarding the multi-ledger functionality.
For a more detailed explanation, we refer to the :ref:`payment client section <payment_client>`.

First of all, we will use special variants of the funder and adjudicator which are located in the ``multi`` package of
go-perun. Essentially, the multi-ledger funder and multi-ledger adjudicator contain a funder or adjudicator for each
ledger identified by its ID. Just for curiosity, we can have a brief look how the multi-ledger funder is actually
implemented in go-perun:

.. literalinclude:: ../source/go-perun/channel/multi/funder.go
   :caption: `👇 This code on GitHub. <https://github.com/hyperledger-labs/go-perun/blob/e831f7ec3d1fee283cc66a3035969a2c7b9aad71/channel/multi/funder.go#L26>`__
   :language: go
   :lines: 26-40

Having this in mind, we can jump back to our code and see how we set up the multi funder & adjudicator (note the
highlighted lines). After we have initialized them, we iterate over the chains array and proceed with creating the
contract backend for this chain, validating the contracts, and create a traditional funder & adjudicator to
register them on the multi-ledger variants.

.. literalinclude:: ../../perun-examples/multiledger-channel/client/client.go
   :emphasize-lines: 3,4,33,38
   :caption: `👇 This code on GitHub. <https://github.com/hyperledger-labs/go-perun/blob/e831f7ec3d1fee283cc66a3035969a2c7b9aad71/channel/multi/funder.go#L26>`__
   :language: go
   :lines: 69-107

After that, we only need to set up a watcher for our client who is watching for events on our multi-ledger adjudicator,
and we have all components ready to create the Perun client by using ``client.New``.

.. literalinclude:: ../../perun-examples/multiledger-channel/client/client.go
   :emphasize-lines: 9
   :caption: `👇 This code on GitHub. <https://github.com/hyperledger-labs/go-perun/blob/e831f7ec3d1fee283cc66a3035969a2c7b9aad71/channel/multi/funder.go#L26>`__
   :language: go
   :lines: 110-121

Finally, we can create our Payment client which gets the Perun client, and then start the handler of the Perun client to
handle channel and update proposals.

.. literalinclude:: ../../perun-examples/multiledger-channel/client/client.go
   :caption: `👇 This code on GitHub. <https://github.com/hyperledger-labs/go-perun/blob/e831f7ec3d1fee283cc66a3035969a2c7b9aad71/channel/multi/funder.go#L26>`__
   :language: go
   :lines: 123-130

Channel opening
...............

The channel opening is again very similar to the payment channel tutorial, the only difference is visible
when setting the allocations of the channel proposal.
There, we now have two assets (the ERC20 tokens) for the two chains for which we need to define the balances for Alice
and Bob.
So, the ``OpenChannel`` method takes two balance arrays for the two chains as an input.

.. literalinclude:: ../../perun-examples/multiledger-channel/client/client.go
   :caption: `👇 This code on GitHub. <https://github.com/hyperledger-labs/go-perun/blob/e831f7ec3d1fee283cc66a3035969a2c7b9aad71/channel/multi/funder.go#L26>`__
   :language: go
   :lines: 135-136

When looking at the ``main.go``, we can see how we would call this function.

.. literalinclude:: ../../perun-examples/multiledger-channel/main.go
   :caption: `👇 This code on GitHub. <https://github.com/hyperledger-labs/go-perun/blob/e831f7ec3d1fee283cc66a3035969a2c7b9aad71/channel/multi/funder.go#L26>`__
   :language: go
   :lines: 77-81


Going back to the ``OpenChannel`` method itself, we can take a look at how we set the allocation for the proposal.
First, we create a new allocation with ``NewAllocation`` which takes the number of participants and the assets of the
channel as an input.
Then, we can set the balances for Alice and Bob for the corresponding asset using the two given balance arrays.

.. literalinclude:: ../../perun-examples/multiledger-channel/client/client.go
   :caption: `👇 This code on GitHub. <https://github.com/hyperledger-labs/go-perun/blob/e831f7ec3d1fee283cc66a3035969a2c7b9aad71/channel/multi/funder.go#L26>`__
   :language: go
   :lines: 143-154


After Alice has sent the channel proposal, Bob will automatically accept the proposal after checking its correctness
(see :ref:`handle proposals <payment_client_handle_proposals>` for more information).

Channel Update
..............

Using the established channel, Alice and Bob can now perform off-chain updates, meaning they can sent each other nearly
instant fee-less payments with the two ERC20 tokens that live on different chains.
For this, we created the ``SendPayment`` method which sends the given amount to the other party. We use the chain index
to specify which asset on which chain we want to use (the chain indices are defined in ``main.go``).

.. literalinclude:: ../../perun-examples/multiledger-channel/client/channel.go
   :caption: `👇 This code on GitHub. <https://github.com/hyperledger-labs/go-perun/blob/e831f7ec3d1fee283cc66a3035969a2c7b9aad71/channel/multi/funder.go#L26>`__
   :language: go
   :lines: 39-40


Channel Settling
................

After Alice and Bob have sent their payments, we want to close the channel such that they receive the channel outcome of
the ERC20 tokens on both chains; here Alice gets 42 tokens of chain B and Bob gets 15 tokens of chain A.
To close the channel, they call the method ``Settle`` which will finalize the channel state, register it on-chain, and
finally withdraw the funds.

.. literalinclude:: ../../perun-examples/multiledger-channel/client/channel.go
   :caption: `👇 This code on GitHub. <https://github.com/hyperledger-labs/go-perun/blob/e831f7ec3d1fee283cc66a3035969a2c7b9aad71/channel/multi/funder.go#L26>`__
   :language: go
   :lines: 54-55


🎉 And that's it for this tutorial, now you know how you can use go-perun for multi-ledger channels!