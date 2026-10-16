# Gauss-Seidel method

Solve a bounded linear system `A x = b` by sequential Gauss-Seidel iteration from the zero vector. Each sweep visits rows in ascending order and immediately uses updated earlier coordinates. Iteration stops when every coordinate changes by less than `1e-10`, or after 1,000 sweeps. The returned coordinates are rounded to ten decimal places, matching the pinned generic Python implementation.

## Contract

- Input is `[n, row-major A entries in micro-units, b entries in micro-units]`, with `n` from 1 through 8. Matrix and vector entries are divided by 1,000,000.
- Entries are signed integers in `[-1,000,000,000, 1,000,000,000]`. The matrix must be exactly symmetric, have positive diagonal entries, and be strictly row-diagonally-dominant. Invalid input returns `-1`.
- Output is `n` little-endian IEEE-754 binary64 values. The function returns `8*n`; insufficient capacity returns `-2`. The oracle solves the system exactly with rational arithmetic, then rounds each result to ten decimal places. Runtime comparisons use absolute and relative tolerances of `1e-8`.

## Source semantics

The canonical source is the pinned [TheAlgorithms Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/numerical_analysis/gauss_seidel_method.py). The pinned [C example](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/numerical_methods/gauss_seidel_method.c) is fixed at three variables and stops when any one coordinate change falls below `1e-4`; the generic Python implementation defines the benchmark contract.

## Workload

[`workload.json`](workload.json) includes systems of several sizes, a zero right-hand side, malformed matrices, and insufficient output capacity. The exact rational oracle is [`benchmarks/gauss_seidel_method_oracle.py`](../../gauss_seidel_method_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/gauss_seidel_method.c`](../../../c/g/gauss_seidel_method.c) |
| C3 | [`c3/g/gauss_seidel_method.c3`](../../../c3/g/gauss_seidel_method.c3) |
| C++ | [`cpp/g/gauss_seidel_method.cpp`](../../../cpp/g/gauss_seidel_method.cpp) |
| Elisa | [`elisa/g/gauss_seidel_method.elisa`](../../../elisa/g/gauss_seidel_method.elisa) |
| Nim | [`nim/g/gauss_seidel_method.nim`](../../../nim/g/gauss_seidel_method.nim) |
| Odin | [`odin/g/gauss_seidel_method.odin`](../../../odin/g/gauss_seidel_method.odin) |
| Rust | [`rust/g/gauss_seidel_method.rs`](../../../rust/g/gauss_seidel_method.rs) |
| V | [`v/g/gauss_seidel_method.v`](../../../v/g/gauss_seidel_method.v) |
| Zig | [`zig/g/gauss_seidel_method.zig`](../../../zig/g/gauss_seidel_method.zig) |

Build with `python3 benchmarks/build_abi.py --algorithm gauss_seidel_method --language LANGUAGE --family i64_array_bytes_output --output-dir build/gauss_seidel_method-LANGUAGE`, then run `python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/gauss_seidel_method-LANGUAGE/build.json`.
