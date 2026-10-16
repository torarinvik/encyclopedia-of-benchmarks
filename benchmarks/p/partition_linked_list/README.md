# Stable linked-list partition

This benchmark models the pinned Python `LinkedList.partition_liked_list` method. It walks the linked list once, appends each node to a less-than-pivot or greater-than-or-equal chain, and joins the chains while preserving encounter order in each group.

## Contract

- Input is `[count, pivot, item...]`, where `count` is 0 through 64 and the pivot and items are signed 32-bit integers.
- The result is a rolling hash modulo 1,000,000,007. Each reordered value contributes `value + 2^31`, using base 2,000,000,003.
- Malformed input returns `-1`.

The bounded array representation captures the source's stable linked-list ordering. This differs from an unstable partition and from sorting: order within each of the two groups stays unchanged.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/partition_linked_list.c`](../../../c/p/partition_linked_list.c) |
| C3 | [`c3/p/partition_linked_list.c3`](../../../c3/p/partition_linked_list.c3) |
| C++ | [`cpp/p/partition_linked_list.cpp`](../../../cpp/p/partition_linked_list.cpp) |
| Elisa | [`elisa/p/partition_linked_list.elisa`](../../../elisa/p/partition_linked_list.elisa) |
| Nim | [`nim/p/partition_linked_list.nim`](../../../nim/p/partition_linked_list.nim) |
| Odin | [`odin/p/partition_linked_list.odin`](../../../odin/p/partition_linked_list.odin) |
| Rust | [`rust/p/partition_linked_list.rs`](../../../rust/p/partition_linked_list.rs) |
| V | [`v/p/partition_linked_list.v`](../../../v/p/partition_linked_list.v) |
| Zig | [`zig/p/partition_linked_list.zig`](../../../zig/p/partition_linked_list.zig) |

## Workload and recording

[`workload.json`](workload.json) covers empty, mixed, all-less, all-greater-or-equal, duplicate, and malformed arrays. The runtime oracle is [`partition_linked_list_oracle.py`](../../partition_linked_list_oracle.py); the array-scalar runner checks expected hashes before recording.

## Pinned source

- [TheAlgorithms/Python `partition_linked_list.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/partition_linked_list.py)
