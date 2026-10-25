# FreeBench Mason search

This package ports the bounded search core from FreeBench's Mason puzzle. A
state places nine labeled pieces on an 18-position board. The search alternates
between three upper and three lower permutations, avoids repeating the same
numbered permutation on adjacent moves, and looks for the target arrangement.
At the source's `mu` layers, a per-piece reachability table prunes states that
cannot reach the target in the remaining four moves.

## Bounded contract

- ABI: `i64_array_scalar`, symbol `freebench_mason`.
- Input: `[a, b, c, d, bi, ar, g1, g2, g3]`. All nine positions must be
  distinct integers from 0 through 17.
- The goal is `a=5`, `b=6`, `c=12`, `d=13`, `bi=14`, `ar=15`, and
  `g1+g2+g3=3`. The recursive search starts in `mu` at depth zero; upper moves
  occur at even depths and lower moves at odd depths. Move ids are tried in
  source order 0, 1, 2, with the previous id excluded.
- Iterative deepening tries bounds 2, 4, 6, and 8. The result is the first
  successful bound, or `-2` if no solution is found by 8. An invalid input
  returns `-1`. A goal at the starting state reports 2 because that is the
  source's first attempted bound.
- The source runs without a depth cap. Its `test.in` reaches a solution at
  bound 32 in the bundled reference output. The bounded package stops at 8;
  this keeps the search cost predictable while preserving the same search and
  pruning rules over the supported bound.
- A full unpruned pass sequence through bound 8 visits at most 1,012 recursive
  states and uses at most nine stack frames. The Python oracle uses breadth-first
  exploration without the source's per-piece prune table.

## Workload and build

[`workload.json`](workload.json) includes an initial goal, two- and four-move
solutions, the pinned `test.in` state at the bound limit, and invalid state
encodings.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm freebench_mason --language rust --with-checker
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/f/freebench_mason/rust/build.json
```

## Provenance and rights

The pinned `mason.c` header states “Copyright (c) 2000 Tord Hansson” but gives
no redistribution permission. There is no separate `LICENSE` file in the
pinned package, so no upstream license is inferred. The ports and oracle are
independently written from the state maps, target condition, search order, and
pruning behavior; they do not copy the C source.

- [Pinned `mason.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/mason/mason.c)
- [Pinned `info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/mason/info.sh)
- [Pinned `test.in`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/mason/test.in)
- [Pinned `ref.in`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/mason/ref.in)
- [Pinned reference output](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/mason/mason.reference_output)

## Language ports

| Language | Source |
| --- | --- |
| C | [c/f/freebench_mason.c](../../../c/f/freebench_mason.c) |
| C3 | [c3/f/freebench_mason.c3](../../../c3/f/freebench_mason.c3) |
| C++ | [cpp/f/freebench_mason.cpp](../../../cpp/f/freebench_mason.cpp) |
| Elisa | [elisa/f/freebench_mason.elisa](../../../elisa/f/freebench_mason.elisa) |
| Nim | [nim/f/freebench_mason.nim](../../../nim/f/freebench_mason.nim) |
| Odin | [odin/f/freebench_mason.odin](../../../odin/f/freebench_mason.odin) |
| Rust | [rust/f/freebench_mason.rs](../../../rust/f/freebench_mason.rs) |
| V | [v/f/freebench_mason.v](../../../v/f/freebench_mason.v) |
| Zig | [zig/f/freebench_mason.zig](../../../zig/f/freebench_mason.zig) |
