Networking
==========

The connection between *Alice* and *Bob* is called "off-chain" since it does not touch
the blockchain. The advantage of off-chain communication is that it is much faster and
confidential.

*go-perun* uses dependency inversion to be as extensible as possible.
This means that you can use your own `Dialer` and `Listener` implementations.
There are three central entities for off-chain connections: `Dialer`,
`Listener` and `Bus`.

The `Dialer` can be used to open connections, the `Listener` accepts connections and the
`Bus` uses both to create a connection between them.

Our network setup uses a TCP/IP-based socket communication and looks like this:

.. literalinclude:: ../../../perun-examples/simple-client/channel.go
   :language: go
   :lines: 31-52

This creates a `Dialer` with a dial-timeout of 10 seconds and adds the other peer with its `Address` and *host*. The `Dialer` can only dial peers that were registered beforehand.
This also applies to incoming connections from other peers, they must be registered in advance.

Then we create a `Listener` that will listen on the *host* once it is started.
A `Bus` is then returned which uses the `Account` and the created `Dialer`.
