# Singly Linked List Deletion

Delete one node by its 1-based position from a singly linked list, then emit the remaining values from head to tail.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[n, position, value_0, ..., value_(n-1)]`, with exact length `n + 2`, `1 <= n <= 64`, and `1 <= position <= n`.
- Each list value must fit signed i32. Invalid framing, count, position, or value returns `-1` before output storage is checked.
- Build a fresh list in input order and apply the pinned `deletion(pos)` operation. Positions are 1-based. The bounded domain uses valid positions, because the source dereferences the requested node for invalid positions.
- Return the remaining list values as little-endian signed i32 bytes, for `4*(n-1)` bytes total (maximum 252 bytes). Deleting the only node succeeds with a zero-byte result.
- Null output or insufficient capacity returns `-2` without writes. Exact output capacity succeeds.

Ports use a fixed node array and next-index links. They unlink either the head or the selected node after its predecessor, then traverse the surviving list. The oracle computes the resulting sequence independently.

## Workload

[`workload.json`](workload.json) covers singleton, head, middle, and tail deletion; duplicate values; signed-i32 boundaries; maximum-size lists; malformed input; null output; and output-capacity boundaries. See the [oracle](../../singly_link_list_deletion_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/singly_link_list_deletion.c`](../../../c/s/singly_link_list_deletion.c) |
| C3 | [`c3/s/singly_link_list_deletion.c3`](../../../c3/s/singly_link_list_deletion.c3) |
| C++ | [`cpp/s/singly_link_list_deletion.cpp`](../../../cpp/s/singly_link_list_deletion.cpp) |
| Elisa | [`elisa/s/singly_link_list_deletion.elisa`](../../../elisa/s/singly_link_list_deletion.elisa) |
| Nim | [`nim/s/singly_link_list_deletion.nim`](../../../nim/s/singly_link_list_deletion.nim) |
| Odin | [`odin/s/singly_link_list_deletion.odin`](../../../odin/s/singly_link_list_deletion.odin) |
| Rust | [`rust/s/singly_link_list_deletion.rs`](../../../rust/s/singly_link_list_deletion.rs) |
| V | [`v/s/singly_link_list_deletion.v`](../../../v/s/singly_link_list_deletion.v) |
| Zig | [`zig/s/singly_link_list_deletion.zig`](../../../zig/s/singly_link_list_deletion.zig) |

## Pinned source

- [TheAlgorithms/C singly linked-list deletion](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/linked_list/singly_link_list_deletion.c) at `e5dad3fa8def3726ec850ca66a7f51521f8ad393`.

The benchmark isolates the source's `deletion(pos)` operation. Its interactive input/output and demonstration entry point are omitted.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm singly_link_list_deletion --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm singly_link_list_deletion
```
