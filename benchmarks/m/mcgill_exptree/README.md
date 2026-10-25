# McGill expression-tree search

This package models the `exptree` launcher in the pinned lac-dcc/Benchmarks
McGill suite. The upstream launcher takes no arguments; its checked-in source
has its input-reading loop commented out and fixes the leaves to `13, 32, 14`
with goal `1412`. Its reference output is `14+13=27; 27*32=864.`. The bounded
suite profile exposes the algorithm's dormant input hook as a small signed-i64
array so that the same search can be benchmarked across multiple cases.

## Contract

- ABI: `i64_array_scalar`, function symbol `mcgill_exptree`.
- Input is `[goal, leaf_count, leaf_0, ..., leaf_(leaf_count-1)]`. There are 1
  through 4 leaves, each in 1..100; the goal is in 1..1,000,000,000. The word
  count must be exactly `leaf_count + 2` and at most 6. These limits keep all
  intermediate values in signed 32-bit range and bound the exhaustive search.
- Each value is used at most once. The search combines currently unused
  work-list entries with `+`, `-`, `*`, and exact `/`, in that order. It
  iteratively deepens from one operation through `leaf_count - 1`. At each
  depth it compares only the value produced by the final combination. It stops
  at the first exact match; otherwise it returns the closest value encountered.
- The source visits first work-list indices in ascending order, then lower
  second indices in ascending order. Ties keep the first candidate. It skips
  zero operands and multiplication or division by one. For subtraction and
  division it sorts operands descending; the source's division divisibility
  check happens before that reordering, and the ports retain that detail.
- The source's `best` variable starts at zero. The ports preserve this sentinel
  behavior, including the one-leaf, goal-1, value-3 case which returns zero.
- Invalid framing or out-of-profile values return `-1`. The independent oracle
  is [`benchmarks/mcgill_exptree_oracle.py`](../../mcgill_exptree_oracle.py).
- The workload is [`workload.json`](workload.json). Its source-fixed case
  returns 864; the scalar ABI exposes the final evaluated result instead of
  reproducing the upstream textual expression trace.

## Pinned provenance

- [`exptree.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/exptree/exptree.c), commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`.
- [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/exptree/info.sh) names the executable `exptree`, lists `exptree.c`, passes no run options, and supplies `-lm` at compile time.
- The C file identifies Pierre Ouellet (ID 9009791). No repository license is
  declared in the repository metadata, and the source file contains no license
  grant. The language ports are independently written from the algorithm
  description and observable behavior; this package does not copy the source.

## Language ports

| Language | Source |
| --- | --- |
| C | [c/m/mcgill_exptree.c](../../../c/m/mcgill_exptree.c) |
| C3 | [c3/m/mcgill_exptree.c3](../../../c3/m/mcgill_exptree.c3) |
| C++ | [cpp/m/mcgill_exptree.cpp](../../../cpp/m/mcgill_exptree.cpp) |
| Elisa | [elisa/m/mcgill_exptree.elisa](../../../elisa/m/mcgill_exptree.elisa) |
| Nim | [nim/m/mcgill_exptree.nim](../../../nim/m/mcgill_exptree.nim) |
| Odin | [odin/m/mcgill_exptree.odin](../../../odin/m/mcgill_exptree.odin) |
| Rust | [rust/m/mcgill_exptree.rs](../../../rust/m/mcgill_exptree.rs) |
| V | [v/m/mcgill_exptree.v](../../../v/m/mcgill_exptree.v) |
| Zig | [zig/m/mcgill_exptree.zig](../../../zig/m/mcgill_exptree.zig) |
