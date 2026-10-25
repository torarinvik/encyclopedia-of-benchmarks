# Olden bisort

This package ports the Olden `bisort` benchmark from `lac-dcc/Benchmarks` at
commit [`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/bisort).
The pinned launcher compiles `args.c` and `bitonic.c` with `-DTORONTO`; it uses
size `700000` when `SMALL_PROBLEM_SIZE` is set and `3000000` otherwise. This
portable profile accepts a source size from 2 through 1,024, capping the tree
at 1,023 allocated nodes. It retains the source's deterministic generator,
recursive tree construction, two tree-aware bitonic passes, and spill value.

The exported scalar function is `bisort(size)`. Its argument is the same size
passed to Olden's `RandTree`; values outside the bound return `-1`. After the
ascending pass and following descending pass, it returns the one-based
position-weighted checksum of the final in-order tree values followed by the
spill value. This makes ordering observable without returning pointer-dependent
diagnostic output. Non-power-of-two sizes follow the source's integer-halving
recursion and its `skiprand(seed, size + 1)` rule.

`NDim`, processor identifiers, and node-level calculations in the source do
not affect the result: with `-DTORONTO`, `NewNode` expands to local allocation
and ignores its processor argument. The pinned files refer to
`olden_v1.0/COPYRIGHT`; that referenced file is absent from this repository
snapshot, so this package does not infer a license. Each implementation is an
independent port.

The oracle builds the same generated value multiset and computes the expected
descending weighted checksum with a flat sort, independent of the ports'
recursive tree merge.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/b/bisort.c](../../../c/b/bisort.c) |
| C3 | [c3/b/bisort.c3](../../../c3/b/bisort.c3) |
| C++ | [cpp/b/bisort.cpp](../../../cpp/b/bisort.cpp) |
| Elisa | [elisa/b/bisort.elisa](../../../elisa/b/bisort.elisa) |
| Nim | [nim/b/bisort.nim](../../../nim/b/bisort.nim) |
| Odin | [odin/b/bisort.odin](../../../odin/b/bisort.odin) |
| Rust | [rust/b/bisort.rs](../../../rust/b/bisort.rs) |
| V | [v/b/bisort.v](../../../v/b/bisort.v) |
| Zig | [zig/b/bisort.zig](../../../zig/b/bisort.zig) |

## Pinned sources

- [`args.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/bisort/args.c)
- [`bitonic.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/bisort/bitonic.c)
- [`node.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/bisort/node.h)
- [`proc.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/bisort/proc.h)
- [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/bisort/info.sh)
