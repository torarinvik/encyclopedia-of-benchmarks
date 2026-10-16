# Flatten Multilevel Linked List

The pinned Java method treats each top-level `next` node as the head of a sorted child chain. It recursively flattens the suffix to the right, then merges the current chain with that suffix. The benchmark encodes those chains as bounded arrays and returns their flattened values. It measures the merge operation and does not model Java object allocation or pointer rewiring.

## Contract

Input is `[column_count, chain_length, values..., ...]` with zero to eight columns. Each nonempty chain has one to eight signed 64-bit values in `[-1000, 1000]`, sorted in nondecreasing order. The output contains the flattened values as little-endian signed 64-bit integers, and the return value is the number of values. Invalid input returns `-1`; a null or undersized output buffer returns `-2`. The maximum output uses 512 bytes.

The merge folds columns from right to left and selects the right chain on equal values, matching the pinned implementation. The ABI exposes values only, so it does not compare object identity or pointer links.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/flatten_multilevel_linked_list.c`](../../../c/f/flatten_multilevel_linked_list.c) |
| C3 | [`c3/f/flatten_multilevel_linked_list.c3`](../../../c3/f/flatten_multilevel_linked_list.c3) |
| C++ | [`cpp/f/flatten_multilevel_linked_list.cpp`](../../../cpp/f/flatten_multilevel_linked_list.cpp) |
| Elisa | [`elisa/f/flatten_multilevel_linked_list.elisa`](../../../elisa/f/flatten_multilevel_linked_list.elisa) |
| Nim | [`nim/f/flatten_multilevel_linked_list.nim`](../../../nim/f/flatten_multilevel_linked_list.nim) |
| Odin | [`odin/f/flatten_multilevel_linked_list.odin`](../../../odin/f/flatten_multilevel_linked_list.odin) |
| Rust | [`rust/f/flatten_multilevel_linked_list.rs`](../../../rust/f/flatten_multilevel_linked_list.rs) |
| V | [`v/f/flatten_multilevel_linked_list.v`](../../../v/f/flatten_multilevel_linked_list.v) |
| Zig | [`zig/f/flatten_multilevel_linked_list.zig`](../../../zig/f/flatten_multilevel_linked_list.zig) |

## Pinned source

[TheAlgorithms/Java `FlattenMultilevelLinkedList.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/FlattenMultilevelLinkedList.java)
