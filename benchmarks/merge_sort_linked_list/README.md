# `merge_sort_linked_list`

This benchmark follows the pinned Python implementation of recursive merge sort on a singly linked list. The portable adapter reads values from a signed 64-bit array, builds a linked list, applies the source's slow/fast split and recursive merge, then emits the sorted node data as little-endian signed 32-bit values.

## Contract

- Input is `[count, value_0, ...]`. `count` is 0 through 128, the input length must be exactly `count + 1`, and values must fit signed 32-bit integers.
- Values must be distinct. The pinned `Node` dataclass orders `data` and then `next`; rejecting duplicate data guarantees comparisons are decided by distinct integer keys and avoids the source's `None`-versus-node tie comparison error.
- Empty and singleton lists are valid and preserve the source's base case. Invalid framing, count, duplicate values, out-of-range values, and null input return `-1` before output-buffer checks.
- Successful calls return the number of output bytes. Results are ascending signed 32-bit values encoded little-endian. A null output pointer or insufficient capacity returns `-2` without writing, including a null pointer for an empty result.
- Maximum input length is 129 signed 64-bit words. Maximum output is 128 values (512 bytes).

The workload covers empty/singleton lists, two-node and odd/even splits, already sorted and interleaved inputs, signed 32-bit boundaries, duplicate-key rejection, maximum size, and exact, short, null, and empty output-buffer cases. The independent [oracle](../merge_sort_linked_list_oracle.py) checks the serialized values and ABI statuses.

## Pinned source

[TheAlgorithms/Python `merge_sort_linked_list.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/merge_sort_linked_list.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Language ports

| Language | Source |
|---|---|
| C | [c/m/merge_sort_linked_list.c](../../c/m/merge_sort_linked_list.c) |
| C3 | [c3/m/merge_sort_linked_list.c3](../../c3/m/merge_sort_linked_list.c3) |
| C++ | [cpp/m/merge_sort_linked_list.cpp](../../cpp/m/merge_sort_linked_list.cpp) |
| Elisa | [elisa/m/merge_sort_linked_list.elisa](../../elisa/m/merge_sort_linked_list.elisa) |
| Nim | [nim/m/merge_sort_linked_list.nim](../../nim/m/merge_sort_linked_list.nim) |
| Odin | [odin/m/merge_sort_linked_list.odin](../../odin/m/merge_sort_linked_list.odin) |
| Rust | [rust/m/merge_sort_linked_list.rs](../../rust/m/merge_sort_linked_list.rs) |
| V | [v/m/merge_sort_linked_list.v](../../v/m/merge_sort_linked_list.v) |
| Zig | [zig/m/merge_sort_linked_list.zig](../../zig/m/merge_sort_linked_list.zig) |
