.. SPDX-FileCopyrightText: 2020 Hyperledger
   SPDX-License-Identifier: CC-BY-4.0

.. _User guide:

User guide
==========

This section will describe the steps to try out a transaction between the
perun-rs node running on a bare metal embedded device and perun-node running on
a computer.

This demo will use perunnode branch on perun-rs repo and perunrs branch on
perun-node repository. These two branches are configured with same default
values, so that they can right away used to try out the demo.

Needed hardware
---------------

This example needs a `STM32 Nucleo F4329ZI
<https://www.st.com/en/evaluation-tools/nucleo-f439zi.html>`_ evaluation board.
However, the library is independent of any hardware and hence can be adapted to
run on other hardwares that support a rust compiler.

Pre-requisites
--------------

To use the perun-rs, the following pre-requisites need to be met.

1. Linux operating system

2. Go (v1.19 or later).

3. Rust and Cargo.

4. A running instance of ganache-cli (v6.9.1 or later).

5. A modem with possibility for LAN connection.

.. note::
   For the code blocks that appear in the following sections, execute them in
   the terminal.

Getting started
---------------

1. Start a blockchain network using ganache-cli node using the below command.
   The three accounts in the command correspond to accounts that will be used in
   default configuration artifacts which we will generate in later steps.
   We fund each of these accounts with 10 ETH each.

.. code-block::

  $ ganache-cli -b 1
  --account="0x1fedd636dbc7e8d41a0622a2040b86fea8842cef9d4aa4c582aad00465b7acff,100000000000000000000"
  --account="0xb0309c60b4622d3071fad3e16c2ce4d0b1e7758316c187754f4dd0cfb44ceb33,100000000000000000000"
  --account="0x403B227E49F55A54743375E8C98C189CA7E0C6D04D3B0ABF78739C703CD2FC7A,100000000000000000000"

2. Clone the perun-node repository and checkout the perunrs branch.

.. code-block::

  $ git clone https://github.com/hyperledger-labs/perun-node.git
  $ cd perun-node
  $ git checkout perunrs

3. Run the tests on perun-node repo.

.. code-block::

  $ go tests -tags=integration -count=1 -p 1 ./...


4. Install the binaries. This will generate three binaries: ``perunnode`` and
   ``perunnode-cli`` and ``perunnode-tui``.

.. code-block::

  $ make install

5. Clone the perun-rs repository, checkout the perunnode branch and update the submodule.

.. code-block::

  $ git clone https://github.com/hyperledger-labs/perun-rs.git
  $ cd perun-rs
  $ git checkout perunnode
  $ git submodule init && git submodule update

6. Run the tests on perun-rs repo.

.. code-block::

  $ cargo +nightly test --all-features

7. Add the microcontroller target to cargo tool chain and install
   needed components.

.. code-block::

   $ rustup +nightly target install thumbv7em-none-eabihf
   $ rustup update
   $ sudo apt-get install gcc-arm-none-eabi

8. Build the code for microcontroller target

.. code-block::

   $ cargo +nighly build --target thumbv7em-none-eabi
   --no-default-features -F k256

Setting up the perun contracts
------------------------------

1. On a new terminal, start perunnodecli app using the below command to start
   an interactive shell.

.. code-block::

  $ ./perunnodecli

.. note::

2. Set the blockchain address and deploy the perun contracts.

.. code-block::

  > chain set-blockchain-address ws://127.0.0.1:8545
  > chain deploy-perun-contracts

Make transactions using the sample application for stm32 board

Using the sample application for STM32 Nucleo board
---------------------------------------------------

1. The blockchain node (ganache-cli) should be running and the contracts should
   be deployed as described in the previous sections.

2. In a second terminal, switch to ``perun-node/demo`` directory with generated
   sample artefacts. Start the node with payment service enabled. This is
   perun-node instance that will be used by the tui client.

.. code-block::

   $ cd perun-node/demo
   $ perunnode run --service payment

3. In a third terminal, also switch to ``perun-node/demo`` directory. Start the
   tui client with alice role.

.. code-block::

   $ perunnodetui -alice

   Connect to the payment service started in previous step by clicking on the
   ``Connect`` button.

   Now, this client is ready to open new channels or handle incoming channel
   requests.

4. Connect an STM32F439ZITx Nucleo board via USB cable to the computer. Also
   connect a LAN cable to it, with the same network as the computer.

5. In a fourth terminal, switch to ``perun-rs`` directory. Run the example
   using the below command.

.. code-block::

   $ cargo +nightly flash --chip STM32F439ZITx --target thumbv7em-none-eabihf -p cortex-m-demo --release

   This will flash the sample application to the mircocontroller. See
   perun-rs/Readme.md for details on how to use this application. Here's a
   short overview we need for this demo.

6. Short overview of the sample application for using perun-rs

   - Green LED: Toggles after every (debounced) button press to indicate it was
     registered

   - Blue LED: Toggles every Second to indicate that the application has not
     crashed

   - Red LED: Toggles if the button press was invalid (for example because the
     channel is already closed). The demo will continue to work normally if the red
     LED roggles.

   - USER Button (Blue, B1): Send 100 WEI to the other participant

   - PA0 (D32), located in CN10, marked as "TIMER", the 3rd pin from the bottom
     (side with the buttons) on the inner side: Send a normal channel closure
     (is_final=true) by connecting it to any GND pin. Only valid if the channel is
     Active.

   - PE0 (D34), located in CN10, marked as "TIMER", the 1st pin from the bottom
     (side with the buttons) on the inner side: Send a force close (dispute
     request) by connecting it to any GND pin. Only valid if the channel is Active.

   - PE2 (D31), located in CN10, marked as "QSPI", the 5th pin from the bottom
     (side with the buttons) on the inner side: Propose a channel by connecting it
     to any GND pin. Only valid if in the `Configured` (Idle) state (we have no
     active channel and are not already in the process of proposing one).
           
7. To start trying out, let's open a channel initiated by the alice (perunnodetui).

   In the tui app command box, type `open bob 1 1` to open a channel with bob
   with an initial balance of 1 ETH each.

   This channel will automatically be accepted by the sample application.

8. Send updates from the perun-node to the sample application.
   
   In the tui app command box, type `send 1 0.1` or `req 1 0.1` to send or
   request funds of 0.1 ETH on channel #1.

   These updates will automatically be accepted by the sample application.

9. Send updates from the sample application to perunnode.

   Press the "USER button". An update request will appear in perunnodetui. Type
   `acc 1` or `rej 1` to accept/reject the update on channel #1.

9. Close the channel by collaboratively, by sending the close command.

   In the tui app command box, type `close 1` to close the channel #1.

   The perun-node will send a final update, which will be accepted by the
   sample application, conclude the channel on the blockchain and withdraw the
   funds.

10. To open a channel initiated by the sample application, connect PE2 PIN to
    GND PIN, when there are no open channels. There will be a request in the
    perunnnode tui application. Let's say the channel number is 2.

    Accept it using the command `acc 2`.

    Then this channel can be used as usual.

11. To close a channel from the sample application, connect the PA0 PIN to GND
    PIN. This will send a finalizing update to perunnodetui.

    Accept it with the command `acc 2` (assuming channel number is 2).

    Followed by this, a channel close request to the funding client. The
    funding client will conclude the channel and withdraw the funds.

    One the channel is conclude, the tui also will withdraw its funds.
