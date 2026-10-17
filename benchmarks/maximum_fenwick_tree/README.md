# Maximum Fenwick tree

This benchmark follows the pinned Python `MaxFenwickTree` point-update and
range-maximum behavior. The structure starts with zeroes, updates assign a new
value (including decreases), and queries use half-open ranges.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[size, operation_count, operation_triples...]`. `size` is 1 through
  64, `operation_count` is 0 through 64, and each operation is exactly three
  signed-i64 words. The exact input length is `2 + 3 * operation_count`, at
  most 194 words.
- Opcode 0 is `[0, index, value]` and assigns a nonnegative signed-i32 value
  at `0 <= index < size`. Opcode 1 is `[1, left, right]` and queries the
  maximum on `[left, right)`, with `0 <= left <= right <= size`. Empty ranges
  return 0. The zero-initialized source uses 0 as its query floor, so negative
  update values are outside the benchmark domain.
- Each query emits one signed-i64 result, little-endian. Updates emit no
  output. Invalid input, a null input pointer, or malformed operations returns
  `-1` before output-buffer checks. Success returns the number of output bytes.
  A null output pointer or insufficient capacity returns `-2` without writing,
  including a null output pointer when no query produced output.
- Maximum output is 512 bytes. The independent oracle is
  [`maximum_fenwick_tree_oracle.py`](../maximum_fenwick_tree_oracle.py).

The workload covers updates that increase and decrease bucket maxima, sibling
maxima, repeated values, empty/singleton/full ranges, invalid bounds and
opcodes, maximum operation/output capacity, and null, zero, short, and exact
output-buffer cases.

## Pinned source

[TheAlgorithms/Python `maximum_fenwick_tree.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/maximum_fenwick_tree.py)
at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Language ports

| Language | Port |
| --- | --- |
| C | [c/m/maximum_fenwick_tree.c](../../c/m/maximum_fenwick_tree.c) |
| C3 | [c3/m/maximum_fenwick_tree.c3](../../c3/m/maximum_fenwick_tree.c3) |
| C++ | [cpp/m/maximum_fenwick_tree.cpp](../../cpp/m/maximum_fenwick_tree.cpp) |
| Elisa | [elisa/m/maximum_fenwick_tree.elisa](../../elisa/m/maximum_fenwick_tree.elisa) |
| Nim | [nim/m/maximum_fenwick_tree.nim](../../nim/m/maximum_fenwick_tree.nim) |
| Odin | [odin/m/maximum_fenwick_tree.odin](../../odin/m/maximum_fenwick_tree.odin) |
| Rust | [rust/m/maximum_fenwick_tree.rs](../../rust/m/maximum_fenwick_tree.rs) |
| V | [v/m/maximum_fenwick_tree.v](../../v/m/maximum_fenwick_tree.v) |
| Zig | [zig/m/maximum_fenwick_tree.zig](../../zig/m/maximum_fenwick_tree.zig) |
