# Linear extension count

This benchmark counts all total orders that satisfy a finite set of precedence
constraints, equivalently all topological orders of the input directed graph.
The primary port uses subset dynamic programming over valid prefixes. A
candidate vertex can be appended exactly when all of its required predecessors
are already in the prefix.

## Contract

The ABI is `i64_array_scalar`; the exported symbol is
`linear_extension_count`. Input is `[n, predecessor_mask[0], ...,
predecessor_mask[n-1]]`, with `0 <= n <= 12`, exact length `n+1`, and each mask
in `[0, 2^n)`. Bit `j` in `predecessor_mask[i]` means that vertex `j` must
appear before vertex `i`. The masks may include redundant transitive
constraints. A cyclic constraint system, including a self-loop, has zero
linear extensions and returns `0`. The empty poset has one extension. Null,
out-of-range, or malformed input returns `-1`. Maximum valid and parseable
lengths are 13 and 14 words.

The result is the exact count of valid orders. At most `12! = 479001600`
orders exist, so all values fit signed 64-bit arithmetic. The primary performs
`O(n 2^n)` transitions and stores `O(2^n)` counts.

## Distinctness and references

This counts every valid order; ordinary topological-sort benchmarks return a
single ordering or a cycle status. It also differs from
[`rooted_tree_topological_order_with_minimum_inversions`](../../r/rooted_tree_topological_order_with_minimum_inversions/README.md),
which optimizes a weighted objective over rooted-tree orders.

The primary oracle mirrors the bottom-up prefix-mask recurrence. The
independent reference recursively removes currently minimal elements and
factors disconnected constraint components using multinomial interleavings.
It does not use the primary's forward prefix table.

The algorithm follows the order-ideal dynamic programming and minimal-element
recurrence described by Kangas, Hankala, Niinimäki, and Koivisto, “Counting Linear
Extensions of Sparse Posets,” *Proceedings of IJCAI 2016*, especially Section
2. The bounded benchmark uses the standard subset state representation of
those ideals. It uses algorithmic ideas only; no source code or paper prose is
copied. See [`RIGHTS.md`](RIGHTS.md).

| Language | Source |
| --- | --- |
| C | [c/l/linear_extension_count.c](../../../c/l/linear_extension_count.c) |
| C3 | [c3/l/linear_extension_count.c3](../../../c3/l/linear_extension_count.c3) |
| C++ | [cpp/l/linear_extension_count.cpp](../../../cpp/l/linear_extension_count.cpp) |
| Elisa | [elisa/l/linear_extension_count.elisa](../../../elisa/l/linear_extension_count.elisa) |
| Mojo | [mojo/l/linear_extension_count.mojo](../../../mojo/l/linear_extension_count.mojo) |
| Nim | [nim/l/linear_extension_count.nim](../../../nim/l/linear_extension_count.nim) |
| Odin | [odin/l/linear_extension_count.odin](../../../odin/l/linear_extension_count.odin) |
| Rust | [rust/l/linear_extension_count.rs](../../../rust/l/linear_extension_count.rs) |
| V | [v/l/linear_extension_count.v](../../../v/l/linear_extension_count.v) |
| Zig | [zig/l/linear_extension_count.zig](../../../zig/l/linear_extension_count.zig) |

The workload includes empty and antichain posets, chains, branching orders,
disconnected components, cycles, maximum-size input, and malformed frames.
`verify_workload.py` checks fixture metadata and package inventory statically.
