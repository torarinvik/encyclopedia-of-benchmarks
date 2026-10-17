# Merge k sorted linked lists

This benchmark follows the pinned Java `MergeKSortedLinkedList.mergeKList`
operation. It merges the values from multiple sorted linked lists into one
ascending list, retaining duplicate values. Each encoded list represents a
separate finite, acyclic node chain, so the input lists are disjoint.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[k, list_0_length, list_0_values..., ...]`. `k` is 0 through 16;
  each list length is 0 through 128; the total number of nodes is at most 128.
  The exact input length is `1 + k + total_node_count`, at most 145 signed-i64
  words. `k` is the number of list heads passed to the source method, so `k=0`
  is a valid empty input.
- Each value must fit signed 32-bit range, and each list must be nondecreasing.
  Empty lists are valid. The output contains all values in ascending order,
  retaining duplicates, as little-endian signed 32-bit integers.
- A null input pointer or malformed input returns `-1` before output-buffer
  checks. Success returns the number of output bytes. A null output pointer or
  insufficient capacity returns `-2` without writing, including a null output
  pointer when all lists are empty.
- Maximum output is 512 bytes. The independent oracle is
  [`merge_ksorted_linked_list_oracle.py`](../merge_ksorted_linked_list_oracle.py).

The workload covers zero and empty lists, interleaving, duplicate values,
negative and boundary values, maximum list and node counts, invalid sortedness
and framing, and null, zero, short, exact, and maximum output capacities.

## Pinned source

[TheAlgorithms/Java `MergeKSortedLinkedList.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/MergeKSortedLinkedList.java)
at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Language ports

| Language | Port |
| --- | --- |
| C | [c/m/merge_ksorted_linked_list.c](../../c/m/merge_ksorted_linked_list.c) |
| C3 | [c3/m/merge_ksorted_linked_list.c3](../../c3/m/merge_ksorted_linked_list.c3) |
| C++ | [cpp/m/merge_ksorted_linked_list.cpp](../../cpp/m/merge_ksorted_linked_list.cpp) |
| Elisa | [elisa/m/merge_ksorted_linked_list.elisa](../../elisa/m/merge_ksorted_linked_list.elisa) |
| Nim | [nim/m/merge_ksorted_linked_list.nim](../../nim/m/merge_ksorted_linked_list.nim) |
| Odin | [odin/m/merge_ksorted_linked_list.odin](../../odin/m/merge_ksorted_linked_list.odin) |
| Rust | [rust/m/merge_ksorted_linked_list.rs](../../rust/m/merge_ksorted_linked_list.rs) |
| V | [v/m/merge_ksorted_linked_list.v](../../v/m/merge_ksorted_linked_list.v) |
| Zig | [zig/m/merge_ksorted_linked_list.zig](../../zig/m/merge_ksorted_linked_list.zig) |
