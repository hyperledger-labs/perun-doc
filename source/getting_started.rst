.. dst-doc documentation master file, created by
   sphinx-quickstart on Thu May 17 17:20:50 2018.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Getting Started
===============

Prerequisites
--------------
#. Install `Go <https://golang.org/doc/install>`_ (v1.10 or later)
#. Install `Geth <https://geth.ethereum.org/install/>`_ (v1.8.20-stable) (Needed only if you like to run walkthrough with a local geth node)

Build and Install
------------------

Build from source
`````````````````````
Use the following commands to build and install dst-go from its source.

Once the GOPATH and GOBIN are properly set in your machine, Run

.. code-block:: bash

    cd $GOPATH
    cd src

    #create directory
    mkdir -p github.com/direct-state-transfer
    cd github.com/direct-state-transfer

    #clone dst-go repo
    git clone https://github.com/direct-state-transfer/dst-go.git
    cd dst-go

After this step, install the govendor tool and run the following commands to sync all the vendored dependencies.

.. code-block:: bash

    #install govendor tool
    go get -u -v github.com/kardianos/govendor

    #sync dependencies
    #should be run inside the cloned root of the dst-go repo (~/PATH/dst-go)
    govendor sync -v

Now all the dependencies are fetched and synced. dst-go can be built and installed using the following steps :

.. code-block:: bash

    #navigate to dst-go module inside the repo
    cd dst-go
    #install dst-go
    go install -v

Now dst-go is installed in your machine and the binary will be available at GOBIN.

Build using Make
````````````````
From your workspace run the following command to clone the dst-go project to your workspace.

.. code-block:: bash

    git clone https://github.com/direct-state-transfer/dst-go.git

You can use the make files available to build dst-go from source.
you can run the following commands from the root of the project repository.
(~/YOUR_WORKSPACE/dst-go/)

To build and install, run

.. code-block:: bash

    make

This command will sync all the vendored dependencies and build the dst-go software.
On successful run, the binary will be available at ~/YOUR_WORKSPACE/dst-go/build/workspace\_/bin

Run Walkthrough
---------------
The walkthrough is nothing but a sample transaction sequence according to Perun protocol between two parties alice and bob.
There are two ways to perform walkthrough, if you are using build and run from source you can able to run the 
walkthrough sequence between two parties in two separate terminals and it will be easy to understand it.

But if you are using make commands to run walkthrough, you can see the walkthrough sequence in only one terminal 
with the outputs printed in different colors to differentiate Alice and Bob sequences.

The walkthrough can be run with geth node (real backend) or with the simulated backend (from go-ethereum project).

If you are using real backend, please look into the following points.


    1. The geth node you are using should be configured to use port number 8546 for WebSocket connection or you have to mention your geth node's WebSocket port number in ~/YOUR_WORKSPACE/dst-go/testdata/test_addresses.json in the place of ethereum node url.
    2. Here is the default test_addresses.json file present in the project. Similarly you can change the ports and ethereum addresses of Alice and Bob.
    
    .. code-block:: json

        {
            "ethereum_node_url" : "ws://localhost:8546",
            "alice_password"   : "",
            "bob_password"     : "",

            "alice_id" : {
                "on_chain_id": "0x932a74da117eb9288ea759487360cd700e7777e1",
                "listener_ip_addr": "localhost:9605",
                "listener_endpoint":"/"
            },
            "bob_id" :{
                "on_chain_id": "0x815430d6ea7275317d09199a5a5675f017e011ef",
                "listener_ip_addr": "localhost:9604",
                "listener_endpoint":"/"
            }

        }
    
    3. Sample configuration is available at testdata with default keys and key files. To use these, simply add the key files from testdata/test-keystore directory to your geth's keystore. To add the test data key file to your geth's keystore, just copy the key files from test-keystore dir in dst-go and paste them in geth's keystore.
    4. The key files of the keys mentioned in the test_addresses.json for Alice and Bob should be present in both our testdata/test-keystore dir and the geth's keystore.
    5. Both the two account addresses used for alice and bob should have a minimum balance of 10 Ethers in each of their account to run this walkthrough.(we advise you not to use mainnet)
    6. If you are using a local geth node and trying to run the walkthrough, make sure the miner is running.
    7. Make sure that you synchronized the vendored dependencies using govendor tool. 

Build and run from source
``````````````````````````
Use the following commands to build and run the walkthrough from source, 

.. code-block:: bash

    cd $GOPATH/src/github.com/direct-state-transfer/dst-go/walkthrough
    #build walkthrough
    go build -v

    #Run walkthrough
    #Initialize bob's node (should be started first) and let it run..
    ./walkthrough --real_backend_bob

    #Open a new terminal and go to walkthrough dir
    cd $GOPATH/src/github.com/direct-state-transfer/dst-go/walkthrough

    #Initialize alice's node and commence walkthrough
    ./walkthrough --real_backend_alice


Now you can see the complete transaction sequence of DST happening between two parties.
Use the help flag to see all the available options.

.. code-block:: none
    
    ./walkthrough -h

      --ch_message_print          Enable/Disable printing of channel messages
      --configFile string         Config file for unit tests (default "../testdata/test_addresses.json")
      --dispute                   Run walkthrough for dispute condition during closure
      --ethereum_address string   Address of ethereum node to connect. Provide complete url
  -h, --help                      help for walkthrough
      --real_backend_alice        Run walkthrough with real backend for alice
      --real_backend_bob          Run walkthrough with real backend for bob
      --simulated_backend         Run walkthrough with simulated backend for both alice and bob
    #Example: 
    ./walkthrough --real_backend_alice --ch_message_print

If you want to run the walkthrough with dispute condition (a dispute between parties while closing the off-chain transaction), 
adding the dispute flag in Alice's command.

Build and run using Make
`````````````````````````
Using the following make commands, you can perform a walkthrough but you can only view the output in one terminal.
You can differentiate the sequences of two parties using the colors of the messages printed.

.. code-block:: bash

    #Go to root of the repository
    cd $YOUR_WORKSPACE/dst-go

    #To run walkthrough with real backend
    make runWalkthrough backend=real

    #To run with simulated backend
    #This will work with the default configuration in testdata
    make runWalkthrough backend=simulated

    #To run with additional flags, you can mention flags like below.
    #example
    make runWalkthrough backend=real flags="--dispute --ch_message_print"

If you like to work with different configurations, 
see :doc:`working_with`.
