# Reverse Linked List

Reverse a nonempty doubly linked list by changing both its `next` and `prev` links.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[n, value_0, ..., value_(n-1)]`, with exact length `n + 1` and `1 <= n <= 256`.
- Values are signed i64 integers. Invalid framing or count returns `-1` before output storage is checked.
- Build a fresh acyclic doubly linked chain in input order and reverse it from its nonnull head. A singleton list remains unchanged.
- Return the values from the new head onward as little-endian signed i64, for `8*n` bytes total (maximum 2,048 bytes).
- Null output or insufficient output capacity returns `-2` without writes.

The pinned PHP `ReverseLinkedList::reverse` updates each node's `prev` pointer and rewires its `next` pointer, then returns the former tail as the new head. The ports use bounded local node indices with both link directions. The PHP `LinkedListItem` class is a required source dependency; its values are untyped, and this ABI bounds them to signed i64 without applying arithmetic to them. Empty/null input is outside the source method's contract.

## Workload

[`workload.json`](workload.json) covers singleton and multi-node reversal, signed-i64 boundaries, maximum size, null/short output, and invalid empty or malformed input. The [oracle](../../reverse_linked_list_oracle.py) reverses a value array independently.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/reverse_linked_list.c`](../../../c/r/reverse_linked_list.c) |
| C3 | [`c3/r/reverse_linked_list.c3`](../../../c3/r/reverse_linked_list.c3) |
| C++ | [`cpp/r/reverse_linked_list.cpp`](../../../cpp/r/reverse_linked_list.cpp) |
| Elisa | [`elisa/r/reverse_linked_list.elisa`](../../../elisa/r/reverse_linked_list.elisa) |
| Nim | [`nim/r/reverse_linked_list.nim`](../../../nim/r/reverse_linked_list.nim) |
| Odin | [`odin/r/reverse_linked_list.odin`](../../../odin/r/reverse_linked_list.odin) |
| Rust | [`rust/r/reverse_linked_list.rs`](../../../rust/r/reverse_linked_list.rs) |
| V | [`v/r/reverse_linked_list.v`](../../../v/r/reverse_linked_list.v) |
| Zig | [`zig/r/reverse_linked_list.zig`](../../../zig/r/reverse_linked_list.zig) |

## Pinned source and required dependency

- TheAlgorithms/PHP [`ReverseLinkedList.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/ReverseLinkedList/ReverseLinkedList.php) at `b8a54469cc36332ef2934101b58d71075ef1d78e`, symbol `DataStructures\ReverseLinkedList\ReverseLinkedList::reverse`.
- Required dependency: TheAlgorithms/PHP [`LinkedListItem.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/ReverseLinkedList/LinkedListItem.php) at the same commit and namespace.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm reverse_linked_list --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm reverse_linked_list
```
