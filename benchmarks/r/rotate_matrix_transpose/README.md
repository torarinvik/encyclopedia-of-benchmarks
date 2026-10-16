# rotate_matrix_transpose

This is the fixed-operation benchmark for the pinned Python `rotate_matrix.transpose` callable. The pinned implementation transposes the matrix in place.

## Contract

- Input is `[rows, columns, row-major signed i64 cells...]`. Dimensions are each `1..32`, and the input must contain exactly `rows * columns` cells. Empty, ragged, or oversized matrices are outside the bounded domain; rectangular nonempty matrices preserve the source’s full `zip` behavior without truncation.
- The wrapper copies input cells to a local matrix representation, applies the selected transform, and returns the transformed matrix as `[output_rows, output_columns, row-major cells...]`. It does not mutate the caller’s input buffer.
- Output encodes every header and cell as one signed i64 in little-endian byte order. Malformed input returns `-1`; insufficient capacity or a null output pointer returns `-2`. Maximum input length is 1,026 i64 values and maximum output is 8,208 bytes.

The independent oracle is [`benchmarks/rotate_matrix_transpose_oracle.py`](../../rotate_matrix_transpose_oracle.py), with shared transformation/encoding logic in [`benchmarks/rotate_matrix_oracle_common.py`](../../rotate_matrix_oracle_common.py). The workload covers source examples, rectangular and degenerate shapes, signed extremes, malformed dimensions/layouts, capacity boundaries, and the maximum matrix.

Pinned source: [TheAlgorithms/Python `rotate_matrix.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/rotate_matrix.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm rotate_matrix_transpose --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm rotate_matrix_transpose
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/rotate_matrix_transpose.c`](../../../c/r/rotate_matrix_transpose.c) |
| C3 | [`c3/r/rotate_matrix_transpose.c3`](../../../c3/r/rotate_matrix_transpose.c3) |
| C++ | [`cpp/r/rotate_matrix_transpose.cpp`](../../../cpp/r/rotate_matrix_transpose.cpp) |
| Elisa | [`elisa/r/rotate_matrix_transpose.elisa`](../../../elisa/r/rotate_matrix_transpose.elisa) |
| Nim | [`nim/r/rotate_matrix_transpose.nim`](../../../nim/r/rotate_matrix_transpose.nim) |
| Odin | [`odin/r/rotate_matrix_transpose.odin`](../../../odin/r/rotate_matrix_transpose.odin) |
| Rust | [`rust/r/rotate_matrix_transpose.rs`](../../../rust/r/rotate_matrix_transpose.rs) |
| V | [`v/r/rotate_matrix_transpose.v`](../../../v/r/rotate_matrix_transpose.v) |
| Zig | [`zig/r/rotate_matrix_transpose.zig`](../../../zig/r/rotate_matrix_transpose.zig) |
