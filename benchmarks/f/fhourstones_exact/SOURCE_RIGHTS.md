# Fhourstones source and rights record

## Pinned sources

Repository: [`lac-dcc/Benchmarks`](https://github.com/lac-dcc/Benchmarks)
Commit: [`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38)

Fhourstones 2.0 source and launcher:

- [`Fhourstones/c4.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones/c4.c)
- [`Fhourstones/play.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones/play.c)
- [`Fhourstones/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones/info.sh)
- [`Fhourstones/input`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones/input)

Fhourstones 3.1 source and launcher:

- [`Fhourstones_31/SearchGame.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones_31/SearchGame.c)
- [`Fhourstones_31/Game.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones_31/Game.h)
- [`Fhourstones_31/TransGame.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones_31/TransGame.h)
- [`Fhourstones_31/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones_31/info.sh)
- [`Fhourstones_31/inputs`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones_31/inputs)
- [`Fhourstones_31/inputs_large`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones_31/inputs_large)

The 2.0 launcher builds `c4.c`, `play.c`, `time.c`, and `trans.c`. The 3.1
launcher builds `SearchGame.c` and selects `inputs` or `inputs_large` according
to `SMALL_PROBLEM_SIZE`. Both launchers feed newline-separated positions using
one-based column characters. The portable suite contract translates those
histories to zero-based integer columns.

## Copyright and restrictions

The 2.0 header identifies John Tromp and states:

> This software is copyright (c) 1996 by John Tromp. This notice must not be
> removed. This software must not be sold for profit. You may redistribute if
> your distributees have the same rights and restrictions.

The 3.1 header identifies John Tromp and states:

> This software is copyright (c) 1996-2005 by John Tromp. This notice must not
> be removed. This software must not be sold for profit. You may redistribute
> if your distributees have the same rights and restrictions.

The pinned directories do not contain a separate license file. Each of the
nine language ports retains both complete source copyright and redistribution
notices in its source header. The package follows the no-sale restriction and
keeps the redistribution condition visible here and in the README.

## Port scope

The two launchers implement the same exact Connect Four solver family. This
package searches legal 7-by-6 positions with 36 through 41 moves, so at most
six cells remain. It keeps exact alpha-beta outcome search and the source's
`-2`, `0`, `2` result categories. It uses center-first ordering and omits the
original transposition table and history heuristic within this deliberately
small contract. The independent Python oracle uses exhaustive minimax and a
separate row-array win detector. The existing local `fourinarow_minimax`
package performs depth-limited heuristic search, so it is not an algorithm
duplicate of this exact endgame package.
