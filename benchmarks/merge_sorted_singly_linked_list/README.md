# Merge two sorted singly linked lists

This benchmark follows the pinned Java `MergeSortedSinglyLinkedList.merge`
implementation. It stably merges two sorted chains and records the source and
original position of each node, making node identity observable in the output.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[lenA, A_values..., lenB, B_values...]`. Each list wrapper is
  non-null; a zero length represents an empty head. The two chains are separate,
  finite, and acyclic. Each length is 0 through 128, their combined length is at
  most 128, and the exact input length is `2 + lenA + lenB` (at most 130
  signed-i64 words).
- Values must fit signed 32-bit range and each list must be nondecreasing. The
  output contains one 12-byte record per node: its signed-i32 value, origin
  (`0` for A or `1` for B), and zero-based position in that input list. Each
  field is encoded as little-endian signed 32-bit. When values tie, A's node is
  emitted first, matching the source's `<=` comparison; node order within each
  list is preserved.
- The pinned implementation relinks and reuses the input nodes. Its Javadoc
  says it creates a new list and leaves the inputs unchanged, but the method
  body links the original nodes into the result. The provenance output records
  that implementation behavior.
- A null input pointer or malformed input returns `-1` before output-buffer
  checks. Success returns the number of output bytes. A null output pointer or
  insufficient capacity returns `-2` without writing, including a null output
  pointer for two empty lists.
- Maximum output is 1536 bytes. The independent oracle is
  [`merge_sorted_singly_linked_list_oracle.py`](../merge_sorted_singly_linked_list_oracle.py).

The workload covers empty inputs, interleaving, duplicate tie stability,
negative and boundary values, maximum sizes, malformed framing and ordering,
and null, zero, short, exact, and maximum output capacities.

## Pinned source

[TheAlgorithms/Java `MergeSortedSinglyLinkedList.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/MergeSortedSinglyLinkedList.java)
at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Language ports

| Language | Port |
| --- | --- |
| C | [c/m/merge_sorted_singly_linked_list.c](../../c/m/merge_sorted_singly_linked_list.c) |
| C3 | [c3/m/merge_sorted_singly_linked_list.c3](../../c3/m/merge_sorted_singly_linked_list.c3) |
| C++ | [cpp/m/merge_sorted_singly_linked_list.cpp](../../cpp/m/merge_sorted_singly_linked_list.cpp) |
| Elisa | [elisa/m/merge_sorted_singly_linked_list.elisa](../../elisa/m/merge_sorted_singly_linked_list.elisa) |
| Nim | [nim/m/merge_sorted_singly_linked_list.nim](../../nim/m/merge_sorted_singly_linked_list.nim) |
| Odin | [odin/m/merge_sorted_singly_linked_list.odin](../../odin/m/merge_sorted_singly_linked_list.odin) |
| Rust | [rust/m/merge_sorted_singly_linked_list.rs](../../rust/m/merge_sorted_singly_linked_list.rs) |
| V | [v/m/merge_sorted_singly_linked_list.v](../../v/m/merge_sorted_singly_linked_list.v) |
| Zig | [zig/m/merge_sorted_singly_linked_list.zig](../../zig/m/merge_sorted_singly_linked_list.zig) |
