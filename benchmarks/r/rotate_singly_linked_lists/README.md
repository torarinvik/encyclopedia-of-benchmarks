# Rotate a Singly Linked List

Rotate a finite singly linked list to the right by a nonnegative number of positions.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[n, k, value_0, ..., value_(n-1)]`, with exact length `n + 2`, `0 <= n <= 64`, and `0 <= k <= 2147483647`.
- Values must fit signed i32. Null input, malformed framing, invalid counts, negative or out-of-range `k`, and invalid values return `-1` before output storage is checked.
- Preserve the pinned Java behavior for empty, singleton, and zero-step lists. For longer lists, rotate right by `k % n` positions by closing the list into a circle and selecting the new tail and head.
- Emit `[n, rotated_value_0, ..., rotated_value_(n-1)]` as little-endian signed i64 values. The count prefix is included; output size is `8 * (n + 1)` bytes (maximum 520).
- Null output or insufficient capacity returns `-2` without writes. Exact capacity succeeds.

Ports represent each node by an index and reproduce the source's circular-link and new-head selection. The oracle computes the expected sequence independently using the rotation formula.

## Workload

[`workload.json`](workload.json) covers empty and singleton lists, zero rotation, ordinary and maximum-step rotation, full multiples of the list length, signed-i32 boundaries, the maximum list size, malformed inputs, null input/output, short capacity, exact capacity, and invalid-input precedence.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/rotate_singly_linked_lists.c`](../../../c/r/rotate_singly_linked_lists.c) |
| C3 | [`c3/r/rotate_singly_linked_lists.c3`](../../../c3/r/rotate_singly_linked_lists.c3) |
| C++ | [`cpp/r/rotate_singly_linked_lists.cpp`](../../../cpp/r/rotate_singly_linked_lists.cpp) |
| Elisa | [`elisa/r/rotate_singly_linked_lists.elisa`](../../../elisa/r/rotate_singly_linked_lists.elisa) |
| Nim | [`nim/r/rotate_singly_linked_lists.nim`](../../../nim/r/rotate_singly_linked_lists.nim) |
| Odin | [`odin/r/rotate_singly_linked_lists.odin`](../../../odin/r/rotate_singly_linked_lists.odin) |
| Rust | [`rust/r/rotate_singly_linked_lists.rs`](../../../rust/r/rotate_singly_linked_lists.rs) |
| V | [`v/r/rotate_singly_linked_lists.v`](../../../v/r/rotate_singly_linked_lists.v) |
| Zig | [`zig/r/rotate_singly_linked_lists.zig`](../../../zig/r/rotate_singly_linked_lists.zig) |

## Pinned source

[TheAlgorithms/Java `RotateSinglyLinkedLists.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/RotateSinglyLinkedLists.java) at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm rotate_singly_linked_lists --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm rotate_singly_linked_lists
```
