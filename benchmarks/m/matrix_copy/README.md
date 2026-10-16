# Matrix Copy

Copy a rectangular integer matrix into a distinct value with the same row-major contents.

## Contract

- The `i64_array_bytes_output` input is `[rows, columns, row-major elements]`. Rows and columns are each 0–32; element values are signed 32-bit integers.
- The output is `[result_rows, result_columns, copied elements...]`, encoded as little-endian signed 64-bit values. For a nonempty matrix the shape and contents are preserved. If either dimension is zero, the Go source returns its zero `Matrix`, so the output shape is normalized to `[0,0]`.
- The packed input must contain exactly `2 + rows*columns` values. Invalid input returns `-1`; insufficient output capacity returns `-2`.

## Source semantics

The pinned [Go `copy.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/matrix/copy.go) allocates a new matrix and copies each element through its `Get` and `Set` methods. It launches one goroutine per row; this shared contract measures the same deep-copy result while leaving goroutine scheduling and synchronization outside the cross-language call. The Go source is licensed under MIT.

## Workload

[`workload.json`](workload.json) covers empty dimensions, single and rectangular matrices, negative values, the maximum 32×32 matrix, malformed input, and insufficient capacity. The oracle is [`matrix_copy_oracle.py`](../../matrix_copy_oracle.py). All nine implementations build and pass the 13 workload cases.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/matrix_copy.c`](../../../c/m/matrix_copy.c) |
| C3 | [`c3/m/matrix_copy.c3`](../../../c3/m/matrix_copy.c3) |
| C++ | [`cpp/m/matrix_copy.cpp`](../../../cpp/m/matrix_copy.cpp) |
| Elisa | [`elisa/m/matrix_copy.elisa`](../../../elisa/m/matrix_copy.elisa) |
| Nim | [`nim/m/matrix_copy.nim`](../../../nim/m/matrix_copy.nim) |
| Odin | [`odin/m/matrix_copy.odin`](../../../odin/m/matrix_copy.odin) |
| Rust | [`rust/m/matrix_copy.rs`](../../../rust/m/matrix_copy.rs) |
| V | [`v/m/matrix_copy.v`](../../../v/m/matrix_copy.v) |
| Zig | [`zig/m/matrix_copy.zig`](../../../zig/m/matrix_copy.zig) |

