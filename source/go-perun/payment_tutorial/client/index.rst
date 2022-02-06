.. _client-index:

Client
=======

We will need one client per participant.
The client object includes multiple tools that fully implement the participant's functionalities required to interact with state channels.
Much of the following implementation can be re-used in other contexts.
Only a few details are specific to our example.

The description is structured into three parts:
First, we will construct the :ref:`client <client>` object, where we implement the channel opening procedure and introduce some utility functions.
Then we define the actual payment :ref:`channel <client-channel>` that provides the client with a basic payment functionality.
Finally, we add the :ref:`handler <client-handle>`, defining the client's reaction to on-chain events.

We put the following implementations in the `client` package.

.. code-block:: go

    package client

.. toctree::
   :hidden:

   client
   channel
   handle
