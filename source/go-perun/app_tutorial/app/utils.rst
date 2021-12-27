Utilities
=========
Before we go on with the app implementation, we need to define a few utilities.
Most are trivial; therefore, we will only look at the important ones here.
These app utilities are implemented in `app/util.go`.

Same Player
~~~~~~~~~~~
`samePlayer()` accepts a list of indices (that refer to particular fields on the Tic-Tac-Toe match field) and checks if the same player marks their respective field.

Start by fetching the value of the first gird index.
Then we compare this with the values of the other fields.
If one of the fields is not set or is set but with another value, we return `false`.
We return `true` with the respective `PlayerIndex` if all fields match.

.. code-block:: go

    func (d TicTacToeAppData) samePlayer(gridIndices ...int) (ok bool, player channel.Index) {
        if len(gridIndices) < 2 {
            panic("expecting at least two inputs")
        }

        first := d.Grid[gridIndices[0]]
        if first == notSet {
            return false, 0
        }
        for _, i := range gridIndices {
            if d.Grid[i] != first {
                return false, 0
            }
        }
        return true, first.PlayerIndex()
    }


Check Final
~~~~~~~~~~~
With `CheckFinal()`, we want to take the current state of the match field and evaluate if the game is finalized, hence if there is a winner (or a draw or if the game is still in progress).

We start by listing all winning possibilities in an array. This is relatively easy for the Tic-Tac-Toe example by looking at the rows, columns, and the two diagonal cases.

.. code-block:: go

    func (d TicTacToeAppData) CheckFinal() (isFinal bool, winner *channel.Index) {
        // 0 1 2
        // 3 4 5
        // 6 7 8

        // Check winner.
        v := [][]int{
            {0, 1, 2}, {3, 4, 5}, {6, 7, 8}, // rows
            {0, 3, 6}, {1, 4, 7}, {2, 5, 8}, // columns
            {0, 4, 8}, {2, 4, 6}, // diagonals
        }

Then we check if one of these combinations is held by one player via the `samePlayer()` method we explained before.
If there is a player, we found a winner and return `true`, including the winner's index `idx`.

.. code-block:: go

        for _, _v := range v {
            ok, idx := d.samePlayer(_v...)
            if ok {
                return true, &idx
            }
        }

If we cannot find a winner, we check if there is a draw or if the game is still in progress.
In case of a draw, we return `true` for `isFinal` with no player index.
Note that the winning/draw check order is essential because there are cases where all grid values are set, but there is one winner.

.. code-block:: go

        // Check all set.
        for _, v := range d.Grid {
            if v != notSet {
                return false, nil
            }
        }
        return true, nil
    return true, nil
    }

Compute Final Balances
~~~~~~~~~~~~~~~~~~~~~~
Finally, we want to implement a function `computeFinalBalances()` that computes the final balances based on the `winner` of the game.

First, we calculate the index of the `loser`.
Notice that the way it is presented in code only works for two-party use cases.
Then we loop through all the assets (in our case, it will only be one: Ethereum).
In our case, "the winner takes it all". Therefore, we add the loser's balance to the winner's and set the balance of the loser to zero.
Ultimately we return the final balance `finalBals`.

.. code-block:: go

    func computeFinalBalances(bals channel.Balances, winner channel.Index) channel.Balances {
        loser := 1 - winner
        finalBals := bals.Clone()
        for i := range finalBals {
            finalBals[i][winner] = new(big.Int).Add(bals[i][0], bals[i][1])
            finalBals[i][loser] = big.NewInt(0)
        }
        return finalBals
    }