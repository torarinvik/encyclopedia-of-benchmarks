# Reverse a Linked List

Reverse a singly linked list by rewiring its links, then emit the values from the new head onward.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[n, value_0, ..., value_(n-1)]`, with exact length `n + 1` and `0 <= n <= 128`.
- Values must fit signed i32. Invalid framing, count, or values return `-1` before output storage is checked.
- Construct a fresh list, append the values in input order, reverse the links, and emit the values in the reversed order. Empty and singleton lists remain unchanged.
- Return the output values as little-endian signed i32, for `4*n` bytes total (maximum 512 bytes).
- Null output returns `-2`, including for an empty list. A nonnull capacity-zero buffer succeeds for an empty list; a short buffer returns `-2` without writes.

The benchmark ports use bounded index-based nodes to model the pinned list operations: tail-scanning append, iterative link reversal, and indexed traversal to collect each output value. They allocate no source list nodes. The independent oracle reverses a Python array. Both pinned C++ files include self-test code and a `main`; the ports reproduce the relevant list behavior without invoking those entry points. The C-Plus-Plus-1 source has no list destructor and leaks its allocated nodes, but that source caveat does not apply to the measured ports. The `n <= 128` bound keeps the quadratic tail-scanning append and indexed traversal practical, and measurement repetitions stay bounded.

## Workload

[`workload.json`](workload.json) covers empty and singleton lists, signed-i32 boundaries, a maximum-size list, null and short output, and invalid framing and values. The [oracle](../../reverse_a_linked_list_oracle.py) computes the reversed sequence independently.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/reverse_a_linked_list.c`](../../../c/r/reverse_a_linked_list.c) |
| C3 | [`c3/r/reverse_a_linked_list.c3`](../../../c3/r/reverse_a_linked_list.c3) |
| C++ | [`cpp/r/reverse_a_linked_list.cpp`](../../../cpp/r/reverse_a_linked_list.cpp) |
| Elisa | [`elisa/r/reverse_a_linked_list.elisa`](../../../elisa/r/reverse_a_linked_list.elisa) |
| Nim | [`nim/r/reverse_a_linked_list.nim`](../../../nim/r/reverse_a_linked_list.nim) |
| Odin | [`odin/r/reverse_a_linked_list.odin`](../../../odin/r/reverse_a_linked_list.odin) |
| Rust | [`rust/r/reverse_a_linked_list.rs`](../../../rust/r/reverse_a_linked_list.rs) |
| V | [`v/r/reverse_a_linked_list.v`](../../../v/r/reverse_a_linked_list.v) |
| Zig | [`zig/r/reverse_a_linked_list.zig`](../../../zig/r/reverse_a_linked_list.zig) |

## Pinned sources

- TheAlgorithms/C-Plus-Plus [`reverse_a_linked_list.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/reverse_a_linked_list.cpp) at `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`.
- TheAlgorithms/C-Plus-Plus-1 [`reverse_a_linked_list.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/reverse_a_linked_list.cpp) at `0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680`.

Both define `data_structures::linked_list::list::insert` and `reverseList`. The first also provides a destructor and deep-copy operations; the second must not be copied and leaks nodes when the list is destroyed.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm reverse_a_linked_list --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm reverse_a_linked_list
```
