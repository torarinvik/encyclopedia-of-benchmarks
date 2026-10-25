# Olden TSP closest-point insertion kernel

This bounded package preserves both `conquer` and `merge` from Olden's
[`tsp` benchmark](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/tsp).
The bounded input uses a deterministic complete heap-shaped point tree with
either three or seven points. The local conquer cutoff is three points; a
seven-point input runs `conquer` on each three-point child and combines those
cycles with the source's Karp merge.

## Contract

- ABI: `i64_array_scalar`, symbol `olden_tsp`.
- Input is `[city_count, x0, y0, ...]`, with `city_count` equal to 3 or 7,
  in heap order (root, left, right, then the next level), and integer
  coordinates in `[-8,8]`.
- Starting from the first point, each later point is inserted into the current
  cycle at the source-selected closest cycle vertex. The adjacent insertion
  side is chosen by the source comparison of the two edge-length changes.
  Strict comparisons preserve the source's list-order tie behavior.
- For seven points, the tree is split into left and right three-point
  subtrees. Each subtree is flattened in source `makelist` post-order and
  passed through `conquer`; the root point is then added by the source's
  four-choice Karp cycle merge, including the source-directed reversals.
- Output is the closed cycle's Euclidean length rounded to the nearest
  thousandth (`floor(length * 1,000 + 0.5)`). This makes the computed route
  observable while keeping the scalar result exact across ports on the
  bounded integer-coordinate domain.
- This is distinct from the local nearest-neighbor solver: Olden inserts the
  next point into an existing cycle, while nearest-neighbor chooses the next
  unvisited city from the current endpoint. The brute-force, Held–Karp,
  genetic, and bitmask packages use other core methods.

The independent [oracle](../../olden_tsp_oracle.py) computes all bounded
results from the closest-point insertion and Karp merge recurrences. See
[workload.json](workload.json) for fixtures.

## Provenance and license

The pinned launcher compiles `args.c`, `build.c`, `main.c`, and `tsp.c` with
`-lm -DTORONTO`; the source leaf threshold is 150. The bounded profile uses
three points as its explicit cutoff so its seven-point case exercises a
complete source merge. The source headers refer
to `olden_v1.0/COPYRIGHT`, but that file is absent from the pinned repository
snapshot, so no upstream license is inferred. These ports are independently
written from the published source data model and algorithm.

## Language ports

| Language | Source |
| --- | --- |
| C | [c/t/olden_tsp.c](../../../c/t/olden_tsp.c) |
| C3 | [c3/t/olden_tsp.c3](../../../c3/t/olden_tsp.c3) |
| C++ | [cpp/t/olden_tsp.cpp](../../../cpp/t/olden_tsp.cpp) |
| Elisa | [elisa/t/olden_tsp.elisa](../../../elisa/t/olden_tsp.elisa) |
| Nim | [nim/t/olden_tsp.nim](../../../nim/t/olden_tsp.nim) |
| Odin | [odin/t/olden_tsp.odin](../../../odin/t/olden_tsp.odin) |
| Rust | [rust/t/olden_tsp.rs](../../../rust/t/olden_tsp.rs) |
| V | [v/t/olden_tsp.v](../../../v/t/olden_tsp.v) |
| Zig | [zig/t/olden_tsp.zig](../../../zig/t/olden_tsp.zig) |

## Pinned source files

- [`tsp.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/tsp/tsp.c)
- [`tsp.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/tsp/tsp.h)
- [`build.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/tsp/build.c)
- [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/tsp/info.sh)
