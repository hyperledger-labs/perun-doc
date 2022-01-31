.. _client-index:

Clients
=======

We will need one Client per participant.
The Client object includes multiple tools that fully implement the participant's functionalities required to interact with state channels.
Much of the following implementation can be re-used in other contexts.
Only a few details is specific to our example.

The description is structured into three parts:
First we will take a look at the payment-channel itself, where we will define the payment functionality.
Then we define the actual Client object that can hold these payment-channels and add the channel opening procedure (+ some utility functionality).
Finally we introduce the Handler, that will define the Clients reaction to on-chain events.

We put the following implementations in the `client` package.

.. code-block:: go

    package client

.. toctree::
   :hidden:

   channel
   client
   handle
