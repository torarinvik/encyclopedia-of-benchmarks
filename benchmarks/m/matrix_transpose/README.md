# matrix_transpose

This package ports the pinned Java `MatrixTranspose.transpose(int[][])` operation. It allocates and returns a transposed matrix with `columns × rows` dimensions.

## Contract

- Input is `[rows, columns, row-major cells...]`. Rows and columns are each bounded to `1..32`; the input must contain exactly `rows * columns` signed i32 cell values. Empty, ragged, null, and oversized matrices are outside the benchmark domain. This preserves the source's rectangular transpose behavior and avoids its exception paths for empty or inconsistent rows.
- Output is `[output_rows, output_columns, row-major transposed cells...]`, encoded as little-endian signed i64 words. The ABI wrapper copies input into local storage and returns a new result, matching the Java method's non-mutating behavior.
- Malformed input returns `-1`. Success returns the number of bytes written; insufficient capacity or a null output pointer returns `-2`. Maximum input length is 1,026 i64 values and maximum output is 8,208 bytes.

The independent oracle is [`benchmarks/matrix_transpose_oracle.py`](../../matrix_transpose_oracle.py). The workload covers source examples, rectangular and one-dimensional matrices, signed i32 boundaries, invalid dimensions/layouts/values, capacity edges, and the maximum matrix.

Pinned source: [TheAlgorithms/Java `MatrixTranspose.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/matrix/MatrixTranspose.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm matrix_transpose --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm matrix_transpose
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/matrix_transpose.c`](../../../c/m/matrix_transpose.c) |
| C3 | [`c3/m/matrix_transpose.c3`](../../../c3/m/matrix_transpose.c3) |
| C++ | [`cpp/m/matrix_transpose.cpp`](../../../cpp/m/matrix_transpose.cpp) |
| Elisa | [`elisa/m/matrix_transpose.elisa`](../../../elisa/m/matrix_transpose.elisa) |
| Nim | [`nim/m/matrix_transpose.nim`](../../../nim/m/matrix_transpose.nim) |
| Odin | [`odin/m/matrix_transpose.odin`](../../../odin/m/matrix_transpose.odin) |
| Rust | [`rust/m/matrix_transpose.rs`](../../../rust/m/matrix_transpose.rs) |
| V | [`v/m/matrix_transpose.v`](../../../v/m/matrix_transpose.v) |
| Zig | [`zig/m/matrix_transpose.zig`](../../../zig/m/matrix_transpose.zig) |
