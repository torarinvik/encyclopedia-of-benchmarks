# Recursive singly linked list search

Search a bounded singly linked list for an integer key using the pinned Java implementation's recursive traversal.

## Contract

- The `i64_array_scalar` ABI accepts `[count, key, values...]` with exactly `count + 2` signed 64-bit integers.
- `count` is in `0..64`; the key and node values are signed 32-bit integers. The maximum input is 66 values.
- Return `1` when any node contains the key and `0` otherwise. Malformed input returns `-1`.
- Each port constructs the list and uses recursive search with first-match short-circuiting. The 64-node bound limits recursion depth.

## Source semantics

This package follows [`SearchSinglyLinkedListRecursion.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/SearchSinglyLinkedListRecursion.java) at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`. Its recursive predicate checks the current node, then recurses to `next` only when the key did not match.

See the [workload](workload.json) and [oracle](../../search_singly_linked_list_recursion_oracle.py).

## Implementations

| Language | Port |
|---|---|
| C | [search_singly_linked_list_recursion.c](../../../c/s/search_singly_linked_list_recursion.c) |
| C3 | [search_singly_linked_list_recursion.c3](../../../c3/s/search_singly_linked_list_recursion.c3) |
| C++ | [search_singly_linked_list_recursion.cpp](../../../cpp/s/search_singly_linked_list_recursion.cpp) |
| Elisa | [search_singly_linked_list_recursion.elisa](../../../elisa/s/search_singly_linked_list_recursion.elisa) |
| Nim | [search_singly_linked_list_recursion.nim](../../../nim/s/search_singly_linked_list_recursion.nim) |
| Odin | [search_singly_linked_list_recursion.odin](../../../odin/s/search_singly_linked_list_recursion.odin) |
| Rust | [search_singly_linked_list_recursion.rs](../../../rust/s/search_singly_linked_list_recursion.rs) |
| V | [search_singly_linked_list_recursion.v](../../../v/s/search_singly_linked_list_recursion.v) |
| Zig | [search_singly_linked_list_recursion.zig](../../../zig/s/search_singly_linked_list_recursion.zig) |
