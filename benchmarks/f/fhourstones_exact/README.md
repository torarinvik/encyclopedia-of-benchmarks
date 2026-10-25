# Fhourstones exact endgame

This package ports the exact Connect Four outcome search from the pinned
`lac-dcc/Benchmarks` Fhourstones 2.0 and Fhourstones 3.1 launchers. Both
versions implement the same 7-column by 6-row solver family; this is one
package, not two duplicate benchmarks. The nearby
[`fourinarow_minimax`](../fourinarow_minimax/README.md) package is a separate
depth-limited heuristic search and does not solve positions to a proven game
outcome.

## Contract

- ABI: `i64_array_scalar`, symbol `fhourstones_exact`.
- Input is `[move_count, column_0, ..., column_(move_count-1)]`.
- Columns are zero-based (`0` through `6`) and moves alternate from player 1.
  Pieces fall to the lowest unoccupied row of the chosen column. Histories must
  be legal, must not contain a four-in-a-row, and must have 36 through 41
  moves, leaving at most six empty cells. The exact array length is
  `move_count + 1`.
- The exact result from the side-to-move perspective is `2` for a forced win,
  `0` for a draw, and `-2` for a forced loss. This preserves Fhourstones 2.0's
  terminal score values; Fhourstones 3.1's `WIN`/`DRAW`/`LOSS` values map to
  the same three outcomes. Invalid input returns `-1`.
- The ports use alpha-beta negamax with center-first move ordering and search
  every remaining legal move until a win or a full board. The six-empty-cell
  limit bounds the tree. They omit the original hash-based transposition table
  and history heuristic, which are not needed to establish the bounded exact
  result. The independent oracle uses an unpruned cell-array minimax and line
  scan.

## Provenance and rights

Source snapshot: [`lac-dcc/Benchmarks` at
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38).
The Fhourstones 2.0 launcher reads `Fhourstones/input`; the 3.1 launcher reads
`Fhourstones_31/inputs` or `inputs_large` according to its problem-size flag.
The 2.0 core is `Fhourstones/c4.c` with board logic in `play.c`; the 3.1 core is
`Fhourstones_31/SearchGame.c` with board and transposition logic in `Game.h` and
`TransGame.h`. These source paths and launchers are pinned in `workload.json`.

Both source versions state that the software is copyrighted by John Tromp, the
notice must not be removed, it must not be sold for profit, and redistribution
is allowed only when recipients have the same rights and restrictions. The
source tree provides these notices in its code headers and does not include a
separate license file. The complete copyright and redistribution notices are
retained in every language port below. These terms prohibit commercial sale of
the included implementations. See [SOURCE_RIGHTS.md](SOURCE_RIGHTS.md) for the
path-by-path source and rights record.

## Language ports

| Language | Source |
| --- | --- |
| C | [c/f/fhourstones_exact.c](../../../c/f/fhourstones_exact.c) |
| C3 | [c3/f/fhourstones_exact.c3](../../../c3/f/fhourstones_exact.c3) |
| C++ | [cpp/f/fhourstones_exact.cpp](../../../cpp/f/fhourstones_exact.cpp) |
| Elisa | [elisa/f/fhourstones_exact.elisa](../../../elisa/f/fhourstones_exact.elisa) |
| Nim | [nim/f/fhourstones_exact.nim](../../../nim/f/fhourstones_exact.nim) |
| Odin | [odin/f/fhourstones_exact.odin](../../../odin/f/fhourstones_exact.odin) |
| Rust | [rust/f/fhourstones_exact.rs](../../../rust/f/fhourstones_exact.rs) |
| V | [v/f/fhourstones_exact.v](../../../v/f/fhourstones_exact.v) |
| Zig | [zig/f/fhourstones_exact.zig](../../../zig/f/fhourstones_exact.zig) |

## Pinned source and license-bearing files

- [`Fhourstones/c4.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones/c4.c)
- [`Fhourstones/play.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones/play.c)
- [`Fhourstones/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones/info.sh)
- [`Fhourstones_31/SearchGame.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones_31/SearchGame.c)
- [`Fhourstones_31/Game.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones_31/Game.h)
- [`Fhourstones_31/TransGame.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones_31/TransGame.h)
- [`Fhourstones_31/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones_31/info.sh)
