# `matmul_f64_4x4`

This package models the pinned LAC-DCC benchmark's repeated unrolled double-precision 4×4 matrix multiplication. The source initializes fixed matrices `A` and `B`, computes `C = A × B` in a loop, and prints the 16 result cells row-major with `%8.2f` formatting. The benchmark ABI exposes the numeric matrix as 16 row-major float64 values; it does not reproduce the source's console formatting.

## Contract

The `float64_slice_io` symbol is `matmul_f64_4x4(input, input_length, output, output_capacity)`. Input is exactly one finite float64 containing an integer iteration count from 1 through 10,000. The profile is bounded below the source's default 50,000,000 iterations. Each product sum follows the source's left-associative four-product order. The function returns 16 and writes the final row-major matrix; invalid input returns -1. For valid input, null output or capacity below 16 returns -2 without writing. Output comparison uses absolute and relative tolerances of `1e-12`.

The independent [oracle](../../matmul_f64_4x4_oracle.py) computes the fixed matrix product in row-major order. [workload.json](workload.json) covers the first, repeated, and maximum bounded iteration counts plus malformed inputs and output-buffer errors.

## Pinned source

- [matmul_f64_4x4.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/matmul_f64_4x4/matmul_f64_4x4.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/matmul_f64_4x4/info.sh)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/matmul_f64_4x4.c](../../../c/m/matmul_f64_4x4.c) |
| C3 | [c3/m/matmul_f64_4x4.c3](../../../c3/m/matmul_f64_4x4.c3) |
| C++ | [cpp/m/matmul_f64_4x4.cpp](../../../cpp/m/matmul_f64_4x4.cpp) |
| Elisa | [elisa/m/matmul_f64_4x4.elisa](../../../elisa/m/matmul_f64_4x4.elisa) |
| Nim | [nim/m/matmul_f64_4x4.nim](../../../nim/m/matmul_f64_4x4.nim) |
| Odin | [odin/m/matmul_f64_4x4.odin](../../../odin/m/matmul_f64_4x4.odin) |
| Rust | [rust/m/matmul_f64_4x4.rs](../../../rust/m/matmul_f64_4x4.rs) |
| V | [v/m/matmul_f64_4x4.v](../../../v/m/matmul_f64_4x4.v) |
| Zig | [zig/m/matmul_f64_4x4.zig](../../../zig/m/matmul_f64_4x4.zig) |
