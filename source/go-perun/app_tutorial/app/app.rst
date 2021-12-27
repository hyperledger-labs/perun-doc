Implementation
--------------
We create the `TicTacToeApp` in `app/app.go`, which implements go-perun's `App` interface that provides the base for our app definition.
The `App` interface comes in two flavors: As `StateApp` or `ActionApp`

- The `StateApp` allows for simple one-sided state updates. This means that one party makes a move, and the state is updated accordingly (e.g., during the move of A, only input of A is needed to form the next state).
- The `ActionApp` is a more fine-grained type. It allows to collect actions from all participants to apply those for a new state (e.g., A and B both contribute to forming the next state).

In our case, the `StateApp` is sufficient because, for the Tic-Tac-Toe game, we only need state updates from one side at a time.

Structure
~~~~~~~~~
The basic structure is straightforward. `TicTacToeApp` is assigned a specific address that links the object to the respective smart contract.
To construct a new `TicTacToeApp` this address needs to be given as an argument. Therefore, the smart contract must be deployed before the object's initialization.

.. code-block:: go

    // TicTacToeApp is a channel app.
    type TicTacToeApp struct {
        Addr wallet.Address
    }

    func NewTicTacToeApp(addr wallet.Address) *TicTacToeApp {
        return &TicTacToeApp{
            Addr: addr,
        }
    }

Definition and Initialize Data
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
We create a getter for the app's smart contract address `Addr` with `Def()`.

.. code-block:: go

    // Def returns the app address.
    func (a *TicTacToeApp) Def() wallet.Address {
        return a.Addr
    }

Further, we create `InitData()`, which wraps the `TicTacToeAppData` constructor to generate a "clean" match field with a given party `firstActor` as the first to be allowed to make a move.

.. code-block:: go

    func (a *TicTacToeApp) InitData(firstActor channel.Index) *TicTacToeAppData {
        return &TicTacToeAppData{
            NextActor: uint8(firstActor),
        }
    }

Decode
~~~~~~
Like `Encode()` is required to encode the game data into a channel state, `Decode()` is needed for converting a game state (given by the Ethereum smart contract) into a `TicTacToeAppData` format for us to use.
We use a few utility functions (implemented in `app/util.go`) in the following.

First, we create an empty `TicTacToeAppData` object that we want to fill with the data (`nextActor`, `grid`) given by the `io.Reader`.
We fetch the actor by calling `readUInt8()`, which reads the first byte of the given data stream.
Then we fetch the grid values by calling `readUInt8Array()`, which reads the next nine bytes of the given data stream.
Finally, we convert the (byte) grid values to their respective field values by calling `makeFieldValueArray()`.

.. code-block:: go

    // DecodeData decodes the channel data.
    func (a *TicTacToeApp) DecodeData(r io.Reader) (channel.Data, error) {
        d := TicTacToeAppData{}

        var err error
        d.NextActor, err = readUInt8(r)
        if err != nil {
            return nil, errors.WithMessage(err, "reading actor")
        }

        grid, err := readUInt8Array(r, len(d.Grid))
        if err != nil {
            return nil, errors.WithMessage(err, "reading grid")
        }
        copy(d.Grid[:], makeFieldValueArray(grid))
        return &d, nil
    }

Validate Initial State
~~~~~~~~~~~~~~~~~~~~~~
We will need to identify if an initial state is valid or not.
Hence, we create `ValidInit()` that takes the channel's parameters `channel.Params` and a channel state `channel.State` as arguments.
If the given arguments do not match the expected ones for a valid app channel initialization, it should return an error.
We will look at the following:

1. Check if the number of actual channel participants matches the expected participants.
2. Validate the data type of the `channel.State`'s data. It must be of type `TicTacToeAppData`.
3. The grid must be empty. This is easily checkable by creating a new instance of `TicTacToeAppData` and comparing its gird with the given one.
4. Verify that the channel state is not finalized. Remember that a final state cannot be further progressed. Therefore it would not make sense to accept one here.
5. Validate the index of the `NextActor`

If no deviations are found, `nil` is returned.

.. code-block:: go

    // ValidInit checks that the initial state is valid.
    func (a *TicTacToeApp) ValidInit(p *channel.Params, s *channel.State) error {
        if len(p.Parts) != numParts {
            return fmt.Errorf("invalid number of participants: expected %d, got %d", numParts, len(p.Parts))
        }

        appData, ok := s.Data.(*TicTacToeAppData)
        if !ok {
            return fmt.Errorf("invalid data type: %T", s.Data)
        }

        zero := TicTacToeAppData{}
        if appData.Grid != zero.Grid {
            return fmt.Errorf("invalid starting grid: %v", appData.Grid)
        }

        if s.IsFinal {
            return fmt.Errorf("must not be final")
        }

        if appData.NextActor >= numParts {
            return fmt.Errorf("invalid next actor: got %d, expected < %d", appData.NextActor, numParts)
        }
        return nil
    }

.. _app-validate-transition:

Validate Transition
~~~~~~~~~~~~~~~~~~~
`ValidTransition()` is a critical part of the app implementation because we check if a given game move is allowed or not.
Therefore, a mistake here could result in not noticing a fraudulent transition (= a game move that is not allowed) and potentially losing the game/funds.

`ValidTransition()` takes the channel's parameters `channel.Params` the old and (proposed) new channel state `channel.State` and the actor index as arguments.

We start by validating the basics:
Check if the given `Data` included in the `channel.State`'s is of the expected type.

.. code-block:: go

    // ValidTransition is called whenever the channel state transitions.
    func (a *TicTacToeApp) ValidTransition(params *channel.Params, from, to *channel.State, idx channel.Index) error {
        err := channel.AssetsAssertEqual(from.Assets, to.Assets)
        if err != nil {
            return fmt.Errorf("Invalid assets: %v", err)
        }

        fromData, ok := from.Data.(*TicTacToeAppData)
        if !ok {
            panic(fmt.Sprintf("from state: invalid data type: %T", from.Data))
        }

        toData, ok := to.Data.(*TicTacToeAppData)
        if !ok {
            panic(fmt.Sprintf("to state: invalid data type: %T", from.Data))
        }

Then we go on by validating the actor.
The proposing actor must differ from the actor of the old state because the game moves are expected to be alternating.
The actor for the next state must match the result of `calcNextActor()` given the previous actor.

.. code-block:: go

        // Check actor.
        if fromData.NextActor != uint8safe(uint16(idx)) {
            return fmt.Errorf("invalid actor: expected %v, got %v", fromData.NextActor, idx)
        }

        // Check next actor.
        if len(params.Parts) != numParts {
            panic("invalid number of participants")
        }
        expectedToNextActor := calcNextActor(fromData.NextActor)
        if toData.NextActor != expectedToNextActor {
            return fmt.Errorf("invalid next actor: expected %v, got %v", expectedToNextActor, toData.NextActor)
        }

Let us continue with checks regarding the match field.
We look at four aspects here:

1. Is the set field value a possible one? This would indicate an invalid turn because not a circle or cross is registered.
2. Does the set field value overwrite another value?
3. Is more than one field manipulated?
4. Is no field manipulated? This would indicate the skipping of the turn.

.. code-block:: go

        // Check grid.
        changed := false
        for i, v := range toData.Grid {
            if v > maxFieldValue {
                return fmt.Errorf("invalid grid value at index %d: %d", i, v)
            }
            vFrom := fromData.Grid[i]
            if v != vFrom {
                if vFrom != notSet {
                    return fmt.Errorf("cannot overwrite field %d", i)
                }
                if changed {
                    return fmt.Errorf("cannot change two fields")
                }
                changed = true
            }
        }
        if !changed {
            return fmt.Errorf("cannot skip turn")
        }

Finally, we check if the proposed state transition resulted in a final state (one party winning or a draw).
We do this by calling earlier describe `CheckFinal()` on the proposed data and validate it with, the in the proposal claimed, final state.

We check if the proposal includes the correct balances if there is a winner.
For this, we calculate the balances on our own via `computeFinalBalances()` and compare the result with the proposed balances.

In the case that all the mentioned checks pass, we accept the transition by returning `nil`.

.. code-block:: go

        // Check final and allocation.
        isFinal, winner := toData.CheckFinal()
        if to.IsFinal != isFinal {
            return fmt.Errorf("final flag: expected %v, got %v", isFinal, to.IsFinal)
        }
        expectedAllocation := from.Allocation.Clone()
        if winner != nil {
            expectedAllocation.Balances = computeFinalBalances(from.Allocation.Balances, *winner)
        }
        if err := expectedAllocation.Equal(&to.Allocation); err != nil {
            return errors.WithMessagef(err, "wrong allocation: expected %v, got %v", expectedAllocation, to.Allocation)
        }
        return nil
    }

.. _app-set:

Set
~~~
`Set()` is responsible for creating the state inside the :ref:`earlier described <app-client-channel-set>` client's `Set()` method.
Therefore we get the `channel.State`, `x`, `y` position, and actor index as arguments.

We again start by making a basic check that the state's app `Data` we want to manipulate is indeed of type `TicTacToeAppData`.
Then we call `Set()` method we implemented earlier in `app/data.go` to perform the manipulation based on `x` and `y`.
Finally, we check if the move eventually lets the client win the game.
We again use `CheckFinal()` for this and compute the respective balances via `computeFinalBalances` in case a `winner` is found.

.. code-block:: go

    func (a *TicTacToeApp) Set(s *channel.State, x, y int, actorIdx channel.Index) error {
        d, ok := s.Data.(*TicTacToeAppData)
        if !ok {
            return fmt.Errorf("invalid data type: %T", d)
        }

        d.Set(x, y, actorIdx)
        log.Println("\n" + d.String())

        if isFinal, winner := d.CheckFinal(); isFinal {
            s.IsFinal = true
            if winner != nil {
                s.Balances = computeFinalBalances(s.Balances, *winner)
            }
        }
        return nil
    }


.. toctree::
   :hidden:
