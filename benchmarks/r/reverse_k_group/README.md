# Reverse K Group

Reverse each complete group of `k` nodes in a singly linked list, leaving any incomplete tail in its original order.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[n, k, value_0, ..., value_(n-1)]`, with exact length `n + 2`, `0 <= n <= 256`, and `1 <= k <= 256`.
- Values are signed i64 integers. Invalid framing, dimensions, `k`, or a null input pointer return `-1` before output storage is checked.
- The result is the linked-list value order after reversing each complete group of `k`. When `k=1` or `k>n`, the values remain unchanged. A trailing group with fewer than `k` nodes also remains unchanged.
- Return the result values in order as little-endian signed i64, for `8*n` bytes total (maximum 2,048 bytes).
- Null output returns `-2`, including for `n=0`. A nonnull capacity-zero buffer succeeds for an empty list; a short buffer returns `-2` without writes.

The pinned Python source builds a fresh `LinkedList`, whose `append` method scans to the tail, then relinks nodes for each complete group. The bounded ports use local node indices and `next` links to preserve that traversal and head-insertion group reversal. The independent oracle uses array-slice reversal instead.

## Workload

[`workload.json`](workload.json) covers positive-length null input, empty and singleton lists, `k=1`, multiple complete groups, an incomplete tail, `k>n`, signed-i64 boundaries, maximum size, and invalid framing and bounds. The [oracle](../../reverse_k_group_oracle.py) computes expected values separately.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/reverse_k_group.c`](../../../c/r/reverse_k_group.c) |
| C3 | [`c3/r/reverse_k_group.c3`](../../../c3/r/reverse_k_group.c3) |
| C++ | [`cpp/r/reverse_k_group.cpp`](../../../cpp/r/reverse_k_group.cpp) |
| Elisa | [`elisa/r/reverse_k_group.elisa`](../../../elisa/r/reverse_k_group.elisa) |
| Nim | [`nim/r/reverse_k_group.nim`](../../../nim/r/reverse_k_group.nim) |
| Odin | [`odin/r/reverse_k_group.odin`](../../../odin/r/reverse_k_group.odin) |
| Rust | [`rust/r/reverse_k_group.rs`](../../../rust/r/reverse_k_group.rs) |
| V | [`v/r/reverse_k_group.v`](../../../v/r/reverse_k_group.v) |
| Zig | [`zig/r/reverse_k_group.zig`](../../../zig/r/reverse_k_group.zig) |

## Pinned source

- TheAlgorithms/Python [`reverse_k_group.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/reverse_k_group.py) at `e1a2a8b016001309a73d5fec4818c35cca139795`, symbol `LinkedList.reverse_k_nodes`.

The similarly named Java candidate is cataloged separately as `reverse_kgroup`; this benchmark follows the Python source contract.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm reverse_k_group --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm reverse_k_group
```
