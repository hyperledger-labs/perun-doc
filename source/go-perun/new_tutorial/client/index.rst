.. _client-index:

Clients
=======

We will need one Client per participant.
Each Client consists of multiple tools and sub-clients that fully implement the participant's functionalities required to interact with state channels.
Much of the following implementation can be re-used in other contexts.
Only a small part is specific to our example.

.. image:: ../../../images/go-perun/client_structure.png
   :align: center
   :width: 300
   :alt: Structure of a payment channel client


Pictured above is the structure of our client implementation.
We will explain everything from the inside to the outside.

As you may notice, our Client's core is the so-called Perun Client.
We start the next section by covering each Perun Client component and streamlining the process of creating an instance of it.
Then we take this knowledge and add the missing pieces to ultimately implement our full Client.

.. toctree::
   :hidden:

   perunclient
   client
