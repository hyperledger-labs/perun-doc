Configuration
=============

There are several ways to load the necessary configuration at startup.
This tutorial will just hard-code all parameters. You could also parse it from command
line flags or read a *json/yaml* file. The configuration parameters are highly dependent on the blockchain that you want to use *go-perun* with. Since this example only uses *Ethereum* it only needs *Ethereum* parameters.

We put all parameters in a `config` struct and create a global `cfg` variable that will
hold the configuration:

.. literalinclude:: ../../../perun-examples/simple-client/config.go
   :language: go
   :lines: 25-33

*Alice* and *Bob* both get a `Role` to define behavior that is specific to them.
This will be used to decide which side of the protocol to execute.

.. literalinclude:: ../../../perun-examples/simple-client/config.go
   :language: go
   :lines: 35-50

Then we need an `init` function that will set all fields of the configuration on startup:

.. literalinclude:: ../../../perun-examples/simple-client/config.go
   :language: go
   :lines: 52-

The on-chain addresses can be hard-coded here since we already know them from the
*ganache-cli* setup.
