# Multi-root hollow heap

This benchmark implements the multi-root hollow heap variant of Hansen,
Kaplan, Tarjan, and Zwick. Decrease-key moves an item to a new node and leaves
its old node hollow; the new node inherits rank `max(0, old_rank - 2)` and the
old node keeps its two highest-ranked children. Delete-min destroys hollow
roots, promotes their children, and links full roots of equal rank. This is a
distinct representation and decrease-key strategy from the local Fibonacci,
binomial, pairing, skew, leftist, and radix heaps.

## Contract

The `i64_array_scalar` input is `[m, (opcode, item_id, value)*m]`, with
`0 <= m <= 64`, exact length `1 + 3*m`, maximum valid length 193, and maximum
parseable length 194. Item IDs are in `0..31`; keys are in `0..1_000_000`.

- Opcode `1` inserts an inactive item ID with the given key.
- Opcode `2` decreases an active item's key to a strictly smaller value.
- Opcode `3` deletes the current minimum and requires both operands to be 0.
- Opcode `4` finds the minimum and requires both operands to be 0.
- Opcode `5` deletes the active item named by `item_id` and requires `value` to
  be 0.

Insert and decrease-key create a new node; inserted nodes start at rank zero.
Decrease-key sets the new node's rank to `max(0, old_rank - 2)` and moves to it
the old node's children whose ranks are below that value. An item ID may be
reused after its item is deleted. Delete-min, find-min, and delete require the
corresponding item or heap state to be nonempty. A nonminimum delete leaves a
hollow node in place; deleting the current minimum destroys hollow roots,
promotes their children, and consolidates roots. Full-root comparisons use
`(key, item_id, node_creation_index)` to choose deterministic minima and link
winners; the heap guarantees the minimum key, with ties resolved through its
root structure. Consolidation repeatedly links the lowest rank that occurs at
least twice, choosing the two lowest node indices at that rank. Find-min and
delete-min each add
`(one_based_operation_index * (key + 1)) + item_id` to the result. Invalid,
null, or incorrectly sized input returns `-1`; a valid trace with no query or
minimum deletion returns `0`.

The ports use bounded index arrays and scan at most 64 nodes to identify roots
and equal-rank pairs. Their adapter work is `O(m^2)` time and `O(m)` space;
the underlying multi-root hollow heap has worst-case `O(1)` insert and
decrease-key and amortized `O(log N)` delete-min, where `N` counts created
nodes.

The package contains two independently organized references and a workload.
Fixtures cover hollow roots and children, decrease-key child movement, rank
consolidation, item-ID reuse, ties, invalid traces, and the maximum frame.
Sources and contracts were reviewed statically; programs and checks have not
been run.

| Language | Port |
|---|---|
| C | [c/m/multi_root_hollow_heap.c](../../../c/m/multi_root_hollow_heap.c) |
| C3 | [c3/m/multi_root_hollow_heap.c3](../../../c3/m/multi_root_hollow_heap.c3) |
| C++ | [cpp/m/multi_root_hollow_heap.cpp](../../../cpp/m/multi_root_hollow_heap.cpp) |
| Elisa | [elisa/m/multi_root_hollow_heap.elisa](../../../elisa/m/multi_root_hollow_heap.elisa) |
| Mojo | [mojo/m/multi_root_hollow_heap.mojo](../../../mojo/m/multi_root_hollow_heap.mojo) |
| Nim | [nim/m/multi_root_hollow_heap.nim](../../../nim/m/multi_root_hollow_heap.nim) |
| Odin | [odin/m/multi_root_hollow_heap.odin](../../../odin/m/multi_root_hollow_heap.odin) |
| Rust | [rust/m/multi_root_hollow_heap.rs](../../../rust/m/multi_root_hollow_heap.rs) |
| V | [v/m/multi_root_hollow_heap.v](../../../v/m/multi_root_hollow_heap.v) |
| Zig | [zig/m/multi_root_hollow_heap.zig](../../../zig/m/multi_root_hollow_heap.zig) |

The structure follows the multi-root variant in Hansen, Kaplan, Tarjan, and
Zwick's [Hollow Heaps](https://doi.org/10.1145/3093240) ([author-hosted
paper](https://arxiv.org/abs/1510.06535)). Only algorithmic ideas are used;
implementations and fixtures are independently written.
