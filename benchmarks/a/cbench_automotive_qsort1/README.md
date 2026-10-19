# cBench automotive_qsort1

This package models the source's `qsort_large` operation: sort 3D integer vectors by ascending Euclidean distance from the origin. The launcher compiles `qsort.c`, `qsort_large.c`, and `loop-wrap.c`; its dataset driver repeats the program, but only the final invocation emits the 100 sampled vectors. This bounded package exposes one deterministic sort call and returns the full sorted vector array, which is a source-related kernel contract rather than the launcher's file-based reporting interface.

## Contract

The exported symbol is `cbench_automotive_qsort1(values, length, output, output_capacity)` under the `i64_array_bytes_output` family. The signed 64-bit input is `[count, x0, y0, z0, ...]`, with 1..128 points and each coordinate in [-1,000,000, 1,000,000]. Frames must contain exactly `1 + 3*count` values. Comparator distances must be unique; equal squared radii are rejected so ordering is unambiguous across languages. This bound keeps every square and sum exact in binary64 and finite. Ordering follows the source comparator, which compares `sqrt(pow(x,2) + pow(y,2) + pow(z,2))`; the ports compute the same bounded sum-of-squares distance. The coordinate and radius restrictions ensure the same strict ordering across binary64 implementations.

Output is 12 bytes per point, in sorted order. Each coordinate is encoded as a signed 32-bit little-endian integer. Invalid input returns -1; a null or undersized output buffer returns -2. Validation happens before capacity checks and output is staged before copying, so failed calls do not write to output. No stability guarantee is needed because equal comparator distances are invalid.

The source algorithm is the custom `qsortx`: midpoint pivot, in-place partition, explicit range stacks, and selection-style `shortsort` for partitions of at most eight points. The C and C++ ports preserve explicit range stacks; the other ports use recursive range dispatch with the same pivot, partition, and cutoff operations. Unique comparator distances make range-dispatch order unobservable in the returned points.

## Workload and oracle

[`workload.json`](workload.json) uses one point as its minimum valid frame. The fixed workload includes a small set and a partition larger than the cutoff; the contract also specifies malformed shape, coordinate-bound, tied-distance, and output-capacity errors. [`benchmarks/cbench_automotive_qsort1_oracle.py`](../../cbench_automotive_qsort1_oracle.py) independently sorts by the source distance expression and encodes the full result.

## Implementations

| Language | Source |
|---|---|
| C | [c/a/cbench_automotive_qsort1.c](../../../c/a/cbench_automotive_qsort1.c) |
| C3 | [c3/a/cbench_automotive_qsort1.c3](../../../c3/a/cbench_automotive_qsort1.c3) |
| C++ | [cpp/a/cbench_automotive_qsort1.cpp](../../../cpp/a/cbench_automotive_qsort1.cpp) |
| Elisa | [elisa/a/cbench_automotive_qsort1.elisa](../../../elisa/a/cbench_automotive_qsort1.elisa) |
| Nim | [nim/a/cbench_automotive_qsort1.nim](../../../nim/a/cbench_automotive_qsort1.nim) |
| Odin | [odin/a/cbench_automotive_qsort1.odin](../../../odin/a/cbench_automotive_qsort1.odin) |
| Rust | [rust/a/cbench_automotive_qsort1.rs](../../../rust/a/cbench_automotive_qsort1.rs) |
| V | [v/a/cbench_automotive_qsort1.v](../../../v/a/cbench_automotive_qsort1.v) |
| Zig | [zig/a/cbench_automotive_qsort1.zig](../../../zig/a/cbench_automotive_qsort1.zig) |

## Pinned source and notices

The launcher and source files are pinned to LAC-DCC/Benchmarks commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`:

- [`src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/automotive_qsort1/src/info.sh)
- [`src/qsort.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/automotive_qsort1/src/qsort.c)
- [`src/qsort_large.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/automotive_qsort1/src/qsort_large.c)
- [`src/loop-wrap.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/automotive_qsort1/src/loop-wrap.c)
- [`LICENSE`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/automotive_qsort1/LICENSE)

The upstream directory notice says “Matt wrote this using STL. It is GPL'ed.” It does not identify a GPL version; this package preserves that notice verbatim and treats the ports as modified derivatives under the stated GPL terms. `qsort.c` separately names Michael Ringgaard and carries the following BSD-style conditions: source redistributions must retain the copyright notice, conditions, and disclaimer; binary redistributions must reproduce them in documentation or other materials; contributor names may not endorse derived products without permission. The source's full warranty/liability disclaimer is retained in each port header; see [LICENSE_NOTICES.md](LICENSE_NOTICES.md). The `qsort.c` copyright is © 2002 Michael Ringgaard.
