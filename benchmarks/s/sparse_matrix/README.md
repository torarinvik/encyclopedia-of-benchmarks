# Sparse Matrix

Classify a matrix as sparse when strictly more than half of its entries are zero, matching the two pinned C++ examples. The package exposes the classification directly as a scalar result and omits the examples' prompts and printed text.

## Contract

- ABI: `i64_array_scalar`.
- Input is `[rows, columns, row_major_entries...]` with exactly `2 + rows * columns` signed 64-bit values.
- Rows and columns are each in `1..=64`. Every entry must fit the pinned source's signed 32-bit `int` type. The maximum valid packed input has 4,098 values.
- The result is `1` when `zero_count > floor(rows * columns / 2)`, and `0` otherwise. This is equivalent to a strict majority of zero entries, including odd-sized matrices.
- Invalid dimensions, framing, or entries return `-1`.

The bounded dimensions keep the C++ `int` product and zero counter in range. This benchmark returns a sparse/not-sparse classification; the separate [`sparsity`](../sparsity/README.md) benchmark returns the proportion of zeros.

## Workload

[`workload.json`](workload.json) covers all-zero and nonzero matrices, exact-half and strict-majority thresholds for even and odd cell counts, signed-int boundaries, maximum dimensions, malformed inputs, and a null input pointer with positive declared length. See the [oracle](../../sparse_matrix_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/sparse_matrix.c`](../../../c/s/sparse_matrix.c) |
| C3 | [`c3/s/sparse_matrix.c3`](../../../c3/s/sparse_matrix.c3) |
| C++ | [`cpp/s/sparse_matrix.cpp`](../../../cpp/s/sparse_matrix.cpp) |
| Elisa | [`elisa/s/sparse_matrix.elisa`](../../../elisa/s/sparse_matrix.elisa) |
| Nim | [`nim/s/sparse_matrix.nim`](../../../nim/s/sparse_matrix.nim) |
| Odin | [`odin/s/sparse_matrix.odin`](../../../odin/s/sparse_matrix.odin) |
| Rust | [`rust/s/sparse_matrix.rs`](../../../rust/s/sparse_matrix.rs) |
| V | [`v/s/sparse_matrix.v`](../../../v/s/sparse_matrix.v) |
| Zig | [`zig/s/sparse_matrix.zig`](../../../zig/s/sparse_matrix.zig) |

## Pinned sources

- [TheAlgorithms/C-Plus-Plus — `others/sparse_matrix.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/sparse_matrix.cpp) at `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`.
- [TheAlgorithms/C-Plus-Plus-1 — `others/sparse_matrix.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/others/sparse_matrix.cpp) at `0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680`.

Both pinned files count entries equal to zero and compare that count against integer half of the matrix size using a strict `>` comparison.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm sparse_matrix --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/s/sparse_matrix/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithm sparse_matrix
```
