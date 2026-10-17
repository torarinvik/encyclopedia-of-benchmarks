# Median of matrix values

This benchmark follows Java `MedianOfMatrix.median`. It skips null rows,
flattens all remaining values, sorts them, and returns the lower median. The
method does not require the input rows to be sorted.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[row_count, row_0_length, row_0_values..., ...]`. `row_count` is 0
  through 16. A row length of `-1` represents a null row; lengths from 0 through
  128 represent non-null rows. The total number of values across non-null rows
  must be 1 through 128. Input framing is exact:
  `1 + row_count + total_value_count` signed-i64 words, at most 145 words.
- Every value must fit signed 32-bit range. Null rows are ignored, empty
  non-null rows contribute no values, and row values may be in any order. An
  input with no values after null and empty rows are skipped is invalid; the
  source method throws for that case.
- Output is the lower median at sorted index `(count - 1) / 2`, encoded as one
  little-endian signed-i32 value. Success returns 4 bytes. A null input pointer
  or invalid input returns `-1` before output checks. A null output pointer or
  capacity below 4 bytes returns `-2` without writing.
- Workspace is 4 bytes. The independent oracle is
  [`median_of_matrix_oracle.py`](../median_of_matrix_oracle.py).

The workload covers odd and even counts, duplicate values, unsorted rows,
ignored null and empty rows, signed boundary values, maximum rows and cells,
invalid empty flattenings, malformed framing, and null, short, and exact output
capacities.

## Pinned source

[TheAlgorithms/Java `MedianOfMatrix.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/matrix/MedianOfMatrix.java)
at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Language ports

| Language | Port |
| --- | --- |
| C | [c/m/median_of_matrix.c](../../c/m/median_of_matrix.c) |
| C3 | [c3/m/median_of_matrix.c3](../../c3/m/median_of_matrix.c3) |
| C++ | [cpp/m/median_of_matrix.cpp](../../cpp/m/median_of_matrix.cpp) |
| Elisa | [elisa/m/median_of_matrix.elisa](../../elisa/m/median_of_matrix.elisa) |
| Nim | [nim/m/median_of_matrix.nim](../../nim/m/median_of_matrix.nim) |
| Odin | [odin/m/median_of_matrix.odin](../../odin/m/median_of_matrix.odin) |
| Rust | [rust/m/median_of_matrix.rs](../../rust/m/median_of_matrix.rs) |
| V | [v/m/median_of_matrix.v](../../v/m/median_of_matrix.v) |
| Zig | [zig/m/median_of_matrix.zig](../../zig/m/median_of_matrix.zig) |
