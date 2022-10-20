App
===
We discussed the basic blocks needed for creating a channel in the :ref:`payment channel example <payment_tutorial_intro>`.
Additional fields in the channel parameters and state are required to define the app logic and state:
An ``app`` field in the parameters stores the address of an on-chain app contract and a ``data`` field in the state is used to insert arbitrary data for describing app states.

We will implement two components in this section:

#. An on-chain contract implementing `Perun's Ethereum App interface <https://github.com/perun-network/perun-eth-contracts/blob/main/contracts/App.sol>`_. Most notably, the interface requires a ``validTransition`` function to validate the transition between app states to make the app logic enforceable without full consensus.
#. An off-chain app implementing `Perun's Core App interface <https://github.com/perun-network/go-perun/blob/main/channel/app.go>`_. It mirrors the on-chain ``validTransition`` function for sanity checks and implements app data encoding.

.. note::
    The contract will act as an on-chain reference to validate the game's state transitions.
    This procedure is only needed in case of disputes.
    The primary point of interaction is still the off-chain app channel.

.. toctree::
   :hidden:

   app_onchain
   app_offchain