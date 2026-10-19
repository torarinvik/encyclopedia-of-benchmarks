# `mccat_qbsort`

This package adapts the two sorting paths in McCat's `01-qbsort` benchmark. Mode `0` performs the source's adjacent-swap BubbleSort; mode `1` performs its recursive, first-element-pivot linked-list QuickSort. Both sort signed 32-bit values in ascending order. Input values are supplied in array order, independent of the source benchmark's text-list parser.

## Contract

- Export `mccat_qbsort` using the `i64_array_bytes_output` ABI. Input is `[mode, count, value_0, ...]`; mode is `0` (BubbleSort) or `1` (QuickSort), count is 1 through 32, and the length must equal `count + 2`.
- Values must fit signed 32-bit integers. Duplicates are allowed. Invalid mode, framing, count, or values return `-1` before output-buffer checks.
- Successful calls return the output byte count. The ascending values are encoded as little-endian signed 32-bit integers. Null output or insufficient capacity returns `-2` without writes.
- The pinned launcher passes repeat count `1000`. Each call repeats its selected sorting path 1,000 times, restoring the original input before each pass, and returns the last result. Input is bounded to 34 signed 64-bit words and output to 128 bytes.
- QuickSort follows the source's head pivot and `< pivot` / `>= pivot` linked-list partitions, recursively sorting the upper partition before the lower partition. BubbleSort uses adjacent swaps in the source's pass order.

The workload records the launcher repeat profile and exercises both modes, duplicates, signed boundaries, invalid frames, and output-buffer errors. The [oracle](../mccat_qbsort_oracle.py) independently checks sorted bytes and ABI statuses.

## Pinned source

[`McCat/01-qbsort`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/01-qbsort) at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`; launcher [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/01-qbsort/info.sh), algorithms [`sort.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/01-qbsort/sort.c), harness `benchmark.c`.

## Language ports

| Language | Source |
|---|---|
| C | [c/m/mccat_qbsort.c](../../c/m/mccat_qbsort.c) |
| C3 | [c3/m/mccat_qbsort.c3](../../c3/m/mccat_qbsort.c3) |
| C++ | [cpp/m/mccat_qbsort.cpp](../../cpp/m/mccat_qbsort.cpp) |
| Elisa | [elisa/m/mccat_qbsort.elisa](../../elisa/m/mccat_qbsort.elisa) |
| Nim | [nim/m/mccat_qbsort.nim](../../nim/m/mccat_qbsort.nim) |
| Odin | [odin/m/mccat_qbsort.odin](../../odin/m/mccat_qbsort.odin) |
| Rust | [rust/m/mccat_qbsort.rs](../../rust/m/mccat_qbsort.rs) |
| V | [v/m/mccat_qbsort.v](../../v/m/mccat_qbsort.v) |
| Zig | [zig/m/mccat_qbsort.zig](../../zig/m/mccat_qbsort.zig) |
