# Sort stack

This benchmark follows the pinned Java `SortStack.sortStack` operation. The
input lists stack entries from bottom to top, so the last value is the initial
top. A successful call sorts the stack in ascending order from bottom to top,
leaving the largest value at the top and retaining duplicates.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[count, bottom_to_top_values...]`. `count` is 0 through 64, the
  exact input length is `1 + count` signed-i64 words, and each value must fit a
  signed 32-bit integer. Maximum input length is 65 words.
- The output contains the sorted values in bottom-to-top order as little-endian
  signed 32-bit integers. Duplicates are retained. Maximum output is 256 bytes.
- A null input pointer, malformed input, invalid count/value, or incorrect
  input length returns `-1` before output checks. Success returns the number of
  output bytes. A null output pointer or insufficient capacity returns `-2`
  without writing, including a null output pointer for an empty stack.
- The independent oracle is
  [`sort_stack_oracle.py`](../../sort_stack_oracle.py).

The workload covers empty and singleton stacks, two-item and longer ordering,
duplicates, signed boundaries, maximum size, invalid input, and exact, short,
null, and zero-byte output-buffer behavior.

## Pinned source

[TheAlgorithms/Java `SortStack.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/SortStack.java)
at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Language ports

| Language | Port |
| --- | --- |
| C | [c/s/sort_stack.c](../../../c/s/sort_stack.c) |
| C3 | [c3/s/sort_stack.c3](../../../c3/s/sort_stack.c3) |
| C++ | [cpp/s/sort_stack.cpp](../../../cpp/s/sort_stack.cpp) |
| Elisa | [elisa/s/sort_stack.elisa](../../../elisa/s/sort_stack.elisa) |
| Nim | [nim/s/sort_stack.nim](../../../nim/s/sort_stack.nim) |
| Odin | [odin/s/sort_stack.odin](../../../odin/s/sort_stack.odin) |
| Rust | [rust/s/sort_stack.rs](../../../rust/s/sort_stack.rs) |
| V | [v/s/sort_stack.v](../../../v/s/sort_stack.v) |
| Zig | [zig/s/sort_stack.zig](../../../zig/s/sort_stack.zig) |
