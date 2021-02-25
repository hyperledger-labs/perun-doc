.. _updating:

Updating
========

We now give the `node` an `updateChannel` function to update the channel by sending Ether from
*Bob* to *Alice*.

.. literalinclude:: ../go-perun-test/node.go
   :language: go
   :lines: 102-115
   :emphasize-lines: 8,9

In the highlighted lines you can see that we use index `0` for the `Balances` slice.
This means that we access the funds of the first asset. Since there is only one asset,
this is the only entry. We also :ref:`finalize <finalizing>` the channel, which will be important later and implies that it can not be updated again.

.. note::

   *go-perun* checks that an update preserves the sum of each asset.

HandleUpdate
^^^^^^^^^^^^

The update that was initiated with the `updateChannel` function above would then arrive
at the `HandleUpdate` function of the other participant. In `HandleUpdate` you can decide on whether you want to accept the incoming update or not.
This example function accepts all updates:

.. literalinclude:: ../go-perun-test/node.go
   :language: go
   :lines: 117-124

An update can also be rejected with a reason. This starts the :ref:`dispute process <disputes>`.

.. code-block:: go

   responder.Reject(ctx, "do not like")

.. _UpdateBy: https://pkg.go.dev/perun.network/go-perun/client#Channel.UpdateBy
.. _Update: https://pkg.go.dev/perun.network/go-perun/client#Channel.Update
