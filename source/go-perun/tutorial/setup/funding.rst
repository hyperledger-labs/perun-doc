Funding
=======

To fund a channel means to send funds to the *AssetHolder* contracts corresponding to the channel assets.
A channel always needs to be funded before it can be opened. The amount that needs to be
deposited is agreed upon by both participants.

*go-perun* needs a `Funder` to fund a channel. Creating a `Funder` looks like this:

.. literalinclude:: ../../../perun-examples/simple-client/channel.go
   :language: go
   :lines: 32-37

As you can see we use an `ETHDepositor` which means that the channel will only be funded with *Ether*.
There is an equivalent `ERC20Depositor` if you need *ERC20 Tokens*.
This function looks complicated since *go-perun* supports multi-asset channels.
In the multi-asset case, you can add more than one `AssetHolder` to the `Accounts` and `Depositors` maps.
