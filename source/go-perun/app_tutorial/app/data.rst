Data
====
Before we implement the actual channel app, we need to structure the game's data.
We implement this data representation in `app/data.go`.

To realize this, we implement `TicTacToeAppData` as the app data struct, which implements the go-perun state `Data` interface.

- `NextActor` represents the next party that is expected to make a move
- `Grid` represents the Tic-Tac-Toe match field. We will define it as an array.

.. code-block:: go

    // TicTacToeAppData is the app data struct.
    type TicTacToeAppData struct {
        NextActor uint8
        Grid      [9]FieldValue
    }



Each index of `Grid` represents a field on the match field. We assign them from the upper left to the lower right:

.. code::

    -------------
    | 0 | 1 | 2 |
    -------------
    | 3 | 4 | 5 |
    -------------
    | 6 | 7 | 8 |
    -------------

Encode
~~~~~~
The `Data` interface requires that `TicTacToeData` can be encoded onto an `io.Writer` via `Encode()`
This method writes our game representation to the given data stream.
It is needed to push the local game data to the smart contract.
Decoding will take place in the app implementation. // TODO: ref

.. code-block:: go

    // Encode encodes app data onto an io.Writer.
    func (d *TicTacToeAppData) Encode(w io.Writer) error {
        err := writeUInt8(w, d.NextActor)
        if err != nil {
            return errors.WithMessage(err, "writing actor")
        }

        err = writeUInt8Array(w, makeUInt8Array(d.Grid[:]))
        return errors.WithMessage(err, "writing grid")
    }

Set
~~~
With `Set()` we implement the manipulation of `TicTacToeData`.
It takes the `x`, `y`, and the index identifying the actor `actorIdx` to write a specific move to the data.

We check if the actor index is valid and fetch the actor's icon (cross or circle).
To get the game filed index from `x` and `y`, we calculate :math:`i = y+3+x` and set `Grid[i]` to the actor's icon.
Finally we update the `NextActor` index with `calcNextActor()`.

.. code-block:: go

    func (d *TicTacToeAppData) Set(x, y int, actorIdx channel.Index) {
        if d.NextActor != uint8safe(uint16(actorIdx)) {
            panic("invalid actor")
        }
        v := makeFieldValueFromPlayerIdx(actorIdx)
        d.Grid[y*3+x] = v
        d.NextActor = calcNextActor(d.NextActor)
    }

    func calcNextActor(actor uint8) uint8 {
        return (actor + 1) % numParts
    }

String and Clone
~~~~~~~~~~~~~~~~
To visualize the grid, we implement a simple `String()` method that prints the match field into the command line.

.. code-block:: go

    func (d *TicTacToeAppData) String() string {
        var b bytes.Buffer
        fmt.Fprintf(&b, "%v|%v|%v\n", d.Grid[0], d.Grid[1], d.Grid[2])
        fmt.Fprintf(&b, "%v|%v|%v\n", d.Grid[3], d.Grid[4], d.Grid[5])
        fmt.Fprintf(&b, "%v|%v|%v\n", d.Grid[6], d.Grid[7], d.Grid[8])
        fmt.Fprintf(&b, "Next actor: %v\n", d.NextActor)
        return b.String()
    }


To allow copying `TicTacToeAppData`, we provide `Clone()` that returns a deep copy of the app data.
The `Data` interface again requires this.

.. code-block:: go

    // Clone returns a deep copy of the app data.
    func (d *TicTacToeAppData) Clone() channel.Data {
        _d := *d
        return &_d
    }

.. toctree::
   :hidden: