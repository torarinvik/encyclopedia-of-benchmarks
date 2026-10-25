# FreeBench Four-in-a-Row minimax

This package implements the bounded depth-limited Connect Four search from
[`FreeBench/fourinarow`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/fourinarow)
at the pinned `lac-dcc/Benchmarks` snapshot. Its two search modes are ordinary
minimax and the source's second alpha-beta implementation. Source comments say
alpha-beta method 1 is not working; this contract rejects that mode. The root
maximizes for computer player 2 and minimizes for human player 1. Candidate
columns are scanned from 0 through 6. Max nodes retain the first equal move;
min nodes retain the last equal move.

## Contract

- ABI: `i64_array_scalar`, symbol `fourinarow_minimax`.
- Input is `[depth, alpha_beta_mode, side, move_count, columns...]`.
- `depth` is 2 through 7; mode is 0 (plain minimax) or 2 (source alpha-beta).
  The pinned launcher uses depth/mode `(7, 2)` in `test.in` and `(9, 2)` in
  `ref.in`. This portable benchmark uses the conservative bounded depth cap 7.
- Side is 1 or 2 and must be the next player after the history. The history
  starts with player 1, alternates players, and each column is 0 through 6.
  Histories contain at most 20 moves, fit the board, and contain no earlier
  four-in-a-row. Inputs violating these bounds return `-1`.
- The board is represented as the source's 42-bit row-major board. The source
  heuristic rewards four/three/two-in-a-row patterns by 1000/20/5, scores
  human patterns negatively and computer patterns positively, and starts its
  recursive root at depth 1 (`off=0`). The package preserves the source mask generation,
  loop order, strict mode-2 cutoffs, and `row * 6` horizontal/diagonal scan
  offsets in `value()` (including that source quirk). It intentionally has no
  terminal-state detection inside the search tree, matching the source.
- Output is `score * 8 + chosen_column`, preserving both the final source
  heuristic score and the selected root column. Invalid input returns `-1`.
- The independent [oracle](../../fourinarow_minimax_oracle.py) computes all
  bounded results. Static fixtures use only hand-derived shallow or invalid
  cases; generated verifier inputs exercise deeper legal histories.

This is a heuristic depth-limited game-tree search. It differs from the
Fhourstones family, which is an exact Connect Four solving benchmark; this
package neither searches to a proven outcome nor uses an exact transposition
table solver.

## Provenance and distribution notice

The pinned source identifies Peter Rundberg (`biff@ce.chalmers.se`) and says:
“Plese feel free to distribute this program as you like.” The spelling is
preserved from the source. No separate license file is present in the pinned
package. The ports and oracle are clean implementations of the documented
algorithm and behavior; this repository retains the source attribution and
distribution notice.

## Language ports

| Language | Source |
| --- | --- |
| C | [c/f/fourinarow_minimax.c](../../../c/f/fourinarow_minimax.c) |
| C3 | [c3/f/fourinarow_minimax.c3](../../../c3/f/fourinarow_minimax.c3) |
| C++ | [cpp/f/fourinarow_minimax.cpp](../../../cpp/f/fourinarow_minimax.cpp) |
| Elisa | [elisa/f/fourinarow_minimax.elisa](../../../elisa/f/fourinarow_minimax.elisa) |
| Nim | [nim/f/fourinarow_minimax.nim](../../../nim/f/fourinarow_minimax.nim) |
| Odin | [odin/f/fourinarow_minimax.odin](../../../odin/f/fourinarow_minimax.odin) |
| Rust | [rust/f/fourinarow_minimax.rs](../../../rust/f/fourinarow_minimax.rs) |
| V | [v/f/fourinarow_minimax.v](../../../v/f/fourinarow_minimax.v) |
| Zig | [zig/f/fourinarow_minimax.zig](../../../zig/f/fourinarow_minimax.zig) |

## Pinned source files

- [`fourinarow.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/fourinarow/fourinarow.c)
- [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/fourinarow/info.sh)
- [`test.in`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/fourinarow/test.in)
- [`ref.in`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/fourinarow/ref.in)
