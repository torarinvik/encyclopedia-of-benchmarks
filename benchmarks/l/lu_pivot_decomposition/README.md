# Pivoted LUP decomposition

This package follows the pinned Dart `Matrix.decompose()` operation. It chooses a partial pivot in each column, swaps rows, and stores the lower and upper factors together in one matrix. It is distinct from the no-pivot Doolittle operation in [`lu_decompose`](../lu_decompose/README.md).

## Contract

The `float64_slice_io` input is `[dimension, matrix_row_major...]`. The dimension is an exact integer in `1..4`; the matrix is square, row-major, and contains exact integer values in `[-8,8]`. At each decomposition step, the selected pivot must be nonzero.

For column `i`, the source scans rows `i..dimension-1` in order and selects the first row with the greatest absolute value in that column. It swaps the selected rows in the packed matrix and swaps the corresponding entries in the pivot vector. The pivot vector starts as `[0, 1, ..., dimension]`; each row swap increments its final entry, so the final value is `dimension + number_of_swaps`. For each row below the pivot, the source divides its column entry by the pivot and subtracts the resulting multiplier times the pivot row from the remaining columns.

The output contains the combined LU matrix in row-major order, followed by the full pivot vector, including its final swap counter. The result code is the output element count, `dimension*dimension + dimension + 1`. Invalid framing, unsupported bounds, fractional matrix entries, or any zero/nonfinite selected pivot returns `-1` before output checks. A null output buffer or insufficient capacity returns `-2` without writes. Output values use absolute and relative tolerances of `1e-12`.

The maximum valid input length is 17 values; one extra value is parseable so trailing data can be rejected. The maximum output length is 21 values.

## Pinned source

The operation is `Matrix.decompose()` from TheAlgorithms/Dart [`lu_decomposition.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/lu_decomposition.dart), pinned at commit `73da8ab4ea413eee9bf29aa2263157d86060f871`. The source's determinant, inversion, solve, and ordinary least-squares helpers are outside this package.

The C++ and Python `lu_decomposition` sources use no-pivot Doolittle decomposition and are covered by the existing [`lu_decompose`](../lu_decompose/README.md) package.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`lu_pivot_decomposition_oracle.py`](../../lu_pivot_decomposition_oracle.py)

## Ports

| Language | Port |
|---|---|
| C | [`c/l/lu_pivot_decomposition.c`](../../../c/l/lu_pivot_decomposition.c) |
| C3 | [`c3/l/lu_pivot_decomposition.c3`](../../../c3/l/lu_pivot_decomposition.c3) |
| C++ | [`cpp/l/lu_pivot_decomposition.cpp`](../../../cpp/l/lu_pivot_decomposition.cpp) |
| Elisa | [`elisa/l/lu_pivot_decomposition.elisa`](../../../elisa/l/lu_pivot_decomposition.elisa) |
| Nim | [`nim/l/lu_pivot_decomposition.nim`](../../../nim/l/lu_pivot_decomposition.nim) |
| Odin | [`odin/l/lu_pivot_decomposition.odin`](../../../odin/l/lu_pivot_decomposition.odin) |
| Rust | [`rust/l/lu_pivot_decomposition.rs`](../../../rust/l/lu_pivot_decomposition.rs) |
| V | [`v/l/lu_pivot_decomposition.v`](../../../v/l/lu_pivot_decomposition.v) |
| Zig | [`zig/l/lu_pivot_decomposition.zig`](../../../zig/l/lu_pivot_decomposition.zig) |
