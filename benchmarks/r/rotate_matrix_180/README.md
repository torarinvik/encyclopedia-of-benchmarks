# rotate_matrix_180

This is the fixed-operation benchmark for the pinned Python `rotate_matrix.rotate_180` callable. The pinned implementation reverses each row and then reverses row order, producing a 180-degree rotation.

## Contract

- Input is `[rows, columns, row-major signed i64 cells...]`. Dimensions are each `1..32`, and the input must contain exactly `rows * columns` cells. Empty, ragged, or oversized matrices are outside the bounded domain; rectangular nonempty matrices preserve the source’s full `zip` behavior without truncation.
- The wrapper copies input cells to a local matrix representation, applies the selected transform, and returns the transformed matrix as `[output_rows, output_columns, row-major cells...]`. It does not mutate the caller’s input buffer.
- Output encodes every header and cell as one signed i64 in little-endian byte order. Malformed input returns `-1`; insufficient capacity or a null output pointer returns `-2`. Maximum input length is 1,026 i64 values and maximum output is 8,208 bytes.

The independent oracle is [`benchmarks/rotate_matrix_180_oracle.py`](../../rotate_matrix_180_oracle.py), with shared transformation/encoding logic in [`benchmarks/rotate_matrix_oracle_common.py`](../../rotate_matrix_oracle_common.py). The workload covers source examples, rectangular and degenerate shapes, signed extremes, malformed dimensions/layouts, capacity boundaries, and the maximum matrix.

Pinned source: [TheAlgorithms/Python `rotate_matrix.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/rotate_matrix.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm rotate_matrix_180 --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm rotate_matrix_180
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/rotate_matrix_180.c`](../../../c/r/rotate_matrix_180.c) |
| C3 | [`c3/r/rotate_matrix_180.c3`](../../../c3/r/rotate_matrix_180.c3) |
| C++ | [`cpp/r/rotate_matrix_180.cpp`](../../../cpp/r/rotate_matrix_180.cpp) |
| Elisa | [`elisa/r/rotate_matrix_180.elisa`](../../../elisa/r/rotate_matrix_180.elisa) |
| Nim | [`nim/r/rotate_matrix_180.nim`](../../../nim/r/rotate_matrix_180.nim) |
| Odin | [`odin/r/rotate_matrix_180.odin`](../../../odin/r/rotate_matrix_180.odin) |
| Rust | [`rust/r/rotate_matrix_180.rs`](../../../rust/r/rotate_matrix_180.rs) |
| V | [`v/r/rotate_matrix_180.v`](../../../v/r/rotate_matrix_180.v) |
| Zig | [`zig/r/rotate_matrix_180.zig`](../../../zig/r/rotate_matrix_180.zig) |
