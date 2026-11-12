# Cartesian tree construction

Construct the min Cartesian tree for a sequence of keys. The tree has the
min-heap property and its in-order traversal visits indices in sequence order.
Each port uses a monotonic stack along the current right spine, taking linear
time and linear auxiliary space. Equal keys use a stable tie rule: the
leftmost minimum is the ancestor.

## Contract

Input is `[N, key_0, ..., key_(N-1)]`, with `1 <= N <= 128` and keys
in `[0, 1,000,000,000]`. The bounded profile extends the official distinct-key
contract with this stable tie rule. Output is `N` signed 64-bit little-endian parent
indices; the root is its own parent. Malformed input returns `-1`; null or
insufficient output returns `-2` without writing. The local bound is kept small
for portable, reviewable cross-language workloads; the official task permits
up to one million keys.

The correctness oracle recursively selects the minimum in each interval, so it
does not share the port's monotonic-stack construction. The certificate helper
checks parent bounds, the heap property, unique root, and in-order indices.

## Distinctness and provenance

This is a linear-time tree-construction algorithm. Treaps and binary-search
trees in the repository support different ordered or dynamic operations and
do not construct the array's unique min Cartesian tree. The high-level task
contract is from [Library Checker — Cartesian Tree](https://github.com/yosupo06/library-checker-problems/blob/master/tree/cartesian_tree/task.md);
the linear right-spine stack method is described in [CP-Algorithms' RMQ article](https://cp-algorithms.com/graph/rmq_linear.html#construction-of-a-cartesian-tree).
The implementations are clean-room ports of the algorithm idea; no upstream
source code, test data, or problem text was copied. The Library Checker problem
repository is Apache-2.0 licensed, and CP-Algorithms content is CC BY-SA 4.0.

[`workload.json`](workload.json) records sorted, reverse-sorted, and mixed
orders, an equal-key case, malformed input, and output-buffer cases.

## Implementations

| Language | Port |
|---|---|
| C | [`c/c/cartesian_tree.c`](../../../c/c/cartesian_tree.c) |
| C3 | [`c3/c/cartesian_tree.c3`](../../../c3/c/cartesian_tree.c3) |
| C++ | [`cpp/c/cartesian_tree.cpp`](../../../cpp/c/cartesian_tree.cpp) |
| Elisa | [`elisa/c/cartesian_tree.elisa`](../../../elisa/c/cartesian_tree.elisa) |
| Mojo | [`mojo/c/cartesian_tree.mojo`](../../../mojo/c/cartesian_tree.mojo) |
| Nim | [`nim/c/cartesian_tree.nim`](../../../nim/c/cartesian_tree.nim) |
| Odin | [`odin/c/cartesian_tree.odin`](../../../odin/c/cartesian_tree.odin) |
| Rust | [`rust/c/cartesian_tree.rs`](../../../rust/c/cartesian_tree.rs) |
| V | [`v/c/cartesian_tree.v`](../../../v/c/cartesian_tree.v) |
| Zig | [`zig/c/cartesian_tree.zig`](../../../zig/c/cartesian_tree.zig) |
