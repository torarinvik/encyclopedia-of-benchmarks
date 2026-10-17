# Spiral print

This benchmark isolates clockwise matrix traversal from the pinned C++ and
Python print helpers. It supplies an existing rectangular matrix and records
the values in spiral order; allocation, demo matrix generation, and console
formatting are outside the contract.

## Contract

- ABI: `i64_array_bytes_output`. The packed input is
  `[rows, cols, row_major_cells...]`, with exact length `2 + rows*cols`.
  Rows are 1–16, columns are 2–16, and each cell is a signed 32-bit integer
  encoded in the i64 input array. The one-column case is excluded because the
  pinned Python print helper duplicates interior left-edge values there.
- Traverse clockwise from the top-left corner: top edge left-to-right, right
  edge top-to-bottom, bottom edge right-to-left, then left edge bottom-to-top,
  continuing inward. C++ `spiralPrint` and Python `spiral_print_clockwise`
  produce the same sequence on this bounded domain. The Python
  `spiral_traversal` helper is a separate return-and-mutate API and is not part
  of this benchmark.
- Output the traversal as little-endian signed 64-bit values, with no count
  prefix. Success returns the output byte length (`8*rows*cols`). Invalid
  dimensions, framing, or cell values return `-1`; a null or undersized output
  buffer returns `-2` without writing, after input validation.
- The maximum valid input has 258 i64 values; the maximum output workspace is
  2,048 bytes.

[`workload.json`](workload.json) includes one-row, one-column-rejected,
rectangular, duplicate, negative, and maximum-size matrices, plus malformed
framing and output-buffer probes. The independent
[oracle](../../spiral_print_oracle.py) implements the boundary traversal and
serializes each value.

## Pinned sources

- TheAlgorithms/C-Plus-Plus [`spiralPrint`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/spiral_print.cpp)
  and the matching [C-Plus-Plus-1 copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/others/spiral_print.cpp)
  print the supplied matrix in clockwise order.
- TheAlgorithms/Python [`spiral_print_clockwise`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/spiral_print.py)
  follows the same order for the bounded domain above. Its separate
  `spiral_traversal` function is not included.

## Build, record, and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm spiral_print --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/s/spiral_print/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm spiral_print --languages rust
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/s/spiral_print.c`](../../../c/s/spiral_print.c) |
| C3 | [`c3/s/spiral_print.c3`](../../../c3/s/spiral_print.c3) |
| C++ | [`cpp/s/spiral_print.cpp`](../../../cpp/s/spiral_print.cpp) |
| Elisa | [`elisa/s/spiral_print.elisa`](../../../elisa/s/spiral_print.elisa) |
| Nim | [`nim/s/spiral_print.nim`](../../../nim/s/spiral_print.nim) |
| Odin | [`odin/s/spiral_print.odin`](../../../odin/s/spiral_print.odin) |
| Rust | [`rust/s/spiral_print.rs`](../../../rust/s/spiral_print.rs) |
| V | [`v/s/spiral_print.v`](../../../v/s/spiral_print.v) |
| Zig | [`zig/s/spiral_print.zig`](../../../zig/s/spiral_print.zig) |
