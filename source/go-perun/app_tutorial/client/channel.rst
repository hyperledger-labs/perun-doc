.. _app-client-channel:

Channel
=======

State channel objects are defined for each type of channel a client participates in to implement channel-specific client-to-channel actions.
In our Tic-Tac-Toe app channel example, we want to allow the client to perform its turn and eventually (& proactively) settle the app channel.
We put this functionality in `client/channel.go`.


As the base, we again use `client.Channel` that comes with go-perun.
We wrap this into a new `AppChannel` object.

.. code-block:: go

    type AppChannel struct {
        ch *client.Channel
    }

.. _app-client-channel-set:

Set
~~~
We create `Set()`, which expects `x` and `y` that indicate where the client wants to make its cross/circle on the playing field.

We use `channel.UpdateBy()` for conveniently proposing our desired update to the channel's `state`.
With `state.App`, we fetch the app that identifies the channel's application and check if it is of the expected type.
Then we call `TicTacToeApp.Set()`, which will manipulate `state.Data` to include the desired turn for us.
`state.Data` holds all app-specific data, therefore reflects the current game state of our Tic-Tac-Toe game.
We will go into more detail about this at :ref:`a later stage <app-set>`.

.. code-block:: go

    func (g *AppChannel) Set(x, y int) {
        err := g.ch.UpdateBy(context.TODO(), func(state *channel.State) error {
            app, ok := state.App.(*app.TicTacToeApp)
            if !ok {
                return fmt.Errorf("invalid app type: %T", app)
            }

            return app.Set(state, x, y, g.ch.Idx())
        })
        if err != nil {
            panic(err) // We panic on error to keep the code simple.
        }
    }

Settle Channel
~~~~~~~~~~~~~~
Settling the channel is quite similar to the way :ref:`we already implemented <client-channel-settle>` in the payment channel tutorial.
But in our case, we can skip the finalization part because we expect the app logic to finalize the channel after the winning move.

.. code-block:: go

    func (g *AppChannel) Settle() {
        // Channel should be finalized through last ("winning") move.
        // No need to set `isFinal` here.
        err := g.ch.Settle(context.TODO(), false)
        if err != nil {
            panic(err)
        }

        // Cleanup.
        g.ch.Close()
    }

.. toctree::
   :hidden:
