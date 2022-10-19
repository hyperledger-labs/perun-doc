.. _multi_ledger_tutorial:

Multi-Ledger Channel Tutorial
-----------------------------

In this tutorial, we will show you how to set up a multi-ledger channel, i.e., a channel that operates between between
multiple (here, 2) chains using go-perun. We will then let two clients, Alice and Bob, swap their ERC20 tokens from the
two different blockchains in this channel.
If you are interested in the technical concept of multi-ledger channels in go-perun, you may take a look at the
`Multi-Ledger Protocol <https://labs.hyperledger.org/perun-doc/concepts/multi_ledger.html>`_ page.
We recommend reading the  :ref:`payment channel tutorial <payment_tutorial_intro>` first since we will reuse most of
the code but it's not a must as we will also explain the relevant parts in this tutorial.


Source Code
...........
This tutorial's source code is available at `perun-examples/multi-ledger-example <https://github.com/perun-network/perun-examples/tree/master/multiledger-channel>`_.

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
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/cae4f17828dc827b293b65f8cd5927ed9a48d975/multiledger-channel/client/client.go#L43>`__
   :language: go
   :lines: 42-49

The ``PaymentClient`` from the payment channel tutorial is extended to our ``SwapClient`` such that it holds an array of
two currencies for the two chains instead of only one.

.. literalinclude:: ../../perun-examples/multiledger-channel/client/client.go
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/cae4f17828dc827b293b65f8cd5927ed9a48d975/multiledger-channel/client/client.go#L52>`__
   :language: go
   :lines: 51-57


Now, we are ready to create the constructor for our ``PaymentClient``, which takes a number of parameters as described
below. Note that the last one is the array of the two chains that we want to use.

.. literalinclude:: ../../perun-examples/multiledger-channel/client/client.go
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/cae4f17828dc827b293b65f8cd5927ed9a48d975/multiledger-channel/client/client.go#L60>`__
   :language: go
   :lines: 59-65

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

Having this in mind, we can jump back to our code and see how we set up the multi funder and adjudicator (note the
highlighted lines). After we have initialized them, we iterate over the chains array.
The first loop only creates the assets which we will register on the funder.
The second loop proceeds with creating the contract backend for this chain, validating the contracts, and create a
traditional funder and adjudicator to register them on the multi-ledger variants.

.. literalinclude:: ../../perun-examples/multiledger-channel/client/client.go
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/cae4f17828dc827b293b65f8cd5927ed9a48d975/multiledger-channel/client/client.go#L66>`__
   :emphasize-lines: 3,4,29,38
   :language: go
   :lines: 66-109

After that, we only need to set up a watcher for our client who is watching for events on our multi-ledger adjudicator,
and we have all components ready to create the Perun client by using ``client.New``.

.. literalinclude:: ../../perun-examples/multiledger-channel/client/client.go
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/cae4f17828dc827b293b65f8cd5927ed9a48d975/multiledger-channel/client/client.go#L111>`__
   :emphasize-lines: 10
   :language: go
   :lines: 111-123

Finally, we can create our Payment client which gets the Perun client, and then start the handler of the Perun client to
handle channel and update proposals.

.. literalinclude:: ../../perun-examples/multiledger-channel/client/client.go
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/cae4f17828dc827b293b65f8cd5927ed9a48d975/multiledger-channel/client/client.go#L125>`__
   :language: go
   :lines: 125-132

Channel opening
...............

The channel opening is again very similar to the payment channel tutorial, the only difference is visible
when setting the allocations of the channel proposal.
There, we will use the type `channel.Balances` which is a two-dimensional array for the assets and the participants.
For example, `balances[0]` gives us the balance array for the first asset and `balances[0][1]` gives us the balance of
the first asset of the second participant.

.. literalinclude:: ../../perun-examples/multiledger-channel/client/client.go
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/cae4f17828dc827b293b65f8cd5927ed9a48d975/multiledger-channel/client/client.go#L137>`__
   :language: go
   :lines: 137-148

When looking at the ``main.go``, we can see how we would initialize this balance array.
Alice inputs 20 PRN (PRN = PerunToken, our ERC20 example token) of chain A and 0 PRN of chain B, and Bob inputs 0 PRN of chain A and 50 PRN of
chain B.

.. literalinclude:: ../../perun-examples/multiledger-channel/main.go
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/cae4f17828dc827b293b65f8cd5927ed9a48d975/multiledger-channel/main.go#L78>`__
   :language: go
   :lines: 78-86


Going back to the ``OpenChannel`` method itself, we can take a look at how we set the allocation for the proposal.
First, we create a new allocation with ``NewAllocation`` which takes the number of participants and the assets of the
channel as an input.
Then, we can set the given balances to the allocation.

.. literalinclude:: ../../perun-examples/multiledger-channel/client/client.go
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/cae4f17828dc827b293b65f8cd5927ed9a48d975/multiledger-channel/client/client.go#L145>`__
   :language: go
   :lines: 145-147


After Alice has sent the channel proposal, Bob will automatically accept the proposal after checking its correctness
(see :ref:`handle proposals <payment_client_handle_proposals>` for more information).

Channel Update
..............

Using the established channel, Alice and Bob can now perform off-chain updates, meaning they can sent each other nearly
instant fee-less payments with the two ERC20 tokens that live on different chains.
In our case, we want to perform a swap which will essentially move all tokens of chain A from Alice to Bob and move all
tokens from chain B from Bob to Alice.
Also, it will make the channel state "final", meaning that there cannot follow any other update after this one, which
allows Alice and Bob to simply settle the channel on-chain afterwards.

.. literalinclude:: ../../perun-examples/multiledger-channel/client/channel.go
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/cae4f17828dc827b293b65f8cd5927ed9a48d975/multiledger-channel/client/channel.go#L40>`__
   :emphasize-lines: 5,7,8,13
   :language: go
   :lines: 38-55

Channel Settling
................

After Alice and Bob have sent their payments, we want to close the channel such that they receive the channel outcome of
the ERC20 tokens on both chains; here Alice gets 50 tokens of chain B and Bob gets 20 tokens of chain A.
To close the channel, they call the method ``Settle`` which will finalize the channel state, register it on-chain, and
finally withdraw the funds.

.. literalinclude:: ../../perun-examples/multiledger-channel/client/channel.go
   :caption: `👇 This code on GitHub. <https://github.com/perun-network/perun-examples/blob/cae4f17828dc827b293b65f8cd5927ed9a48d975/multiledger-channel/client/channel.go#L58>`__
   :language: go
   :lines: 57-58


🎉 And that's it for this tutorial, now you know how you can use go-perun for multi-ledger channels!