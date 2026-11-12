# Rooted tree topological order with minimum inversions

This package finds an optimal linear extension of a rooted tree under the
weighted pair objective

`X = sum over later v of C[v] * sum(D[u] for every earlier u)`.

Every ancestor must appear before its descendants. This is a weighted ordering
optimization; it is distinct from ordinary topological sorting, counting
unweighted inversions, and minimizing a tree-path or edge cost.

## Method and bounded profile

The implementation contracts components into their current parent component.
At each step it selects the available nonroot component with maximum aggregate
`C/D` ratio, compared by cross products. `(C,D)=(0,0)` is treated as the
smallest ratio; equal ratios select the larger current component label first.
Contraction updates the aggregate weights and swaps the corresponding linked
list links. Reversing the resulting list yields the topological order. These
rules make the returned order deterministic, although the contract accepts any
optimal order.

For a compact local profile, each port scans at most 12 current components to
select the next maximum, giving `O(N^2)` time and `O(N)` storage. All ratio
cross-products and the objective fit signed 64-bit arithmetic under the local
sum limits.

The input is a signed 64-bit word array `[N,parent[1..N-1],C[0..N-1],D[0..N-1]]`.
The local profile uses `1 <= N <= 12`, valid parent indices `0 <= parent[i] < i`,
nonnegative weights at most 1,000,000, and each total weight sum at most
1,000,000. It accepts one extra parseable word only to reject trailing input.

Output is a little-endian signed 64-bit word vector `[X,v0,...,vN-1]`, at most
104 bytes. Invalid input returns `-1`; a null or undersized output buffer
returns `-2` without writing. `workspace.bytes` is the output-buffer capacity;
the bounded arrays are additional internal storage.

The official task permits `N <= 200,000` and total `C` and `D` sums up to
1,000,000,000. This benchmark uses a smaller profile and the same ratio
contraction principle, with a linear scan for each selection.

## Oracle and package checker

The primary
[`benchmarks/rooted_tree_topological_order_with_minimum_inversions_oracle.py`](../../rooted_tree_topological_order_with_minimum_inversions_oracle.py)
implements the contraction and deterministic tie rules. The independent
[`benchmarks/rooted_tree_topological_order_with_minimum_inversions_checker.py`](../../rooted_tree_topological_order_with_minimum_inversions_checker.py)
uses subset dynamic programming over ancestor-valid prefixes, then checks
permutation validity and recomputes the objective. It verifies optimality
without requiring a particular permutation among tied optima. The package-local
[`verify_rooted_tree_topological_order_with_minimum_inversions_package.py`](verify_rooted_tree_topological_order_with_minimum_inversions_package.py)
statically checks metadata, fixture bytes, certificates, and all language ports.

Official contract: [Library Checker task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/tree/rooted_tree_topological_order_with_minimum_inversions/task.md)
and [limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/tree/rooted_tree_topological_order_with_minimum_inversions/info.toml).
All ports are clean-room implementations of the bounded profile.

## Implementations

| Language | Source |
|---|---|
| C | [`c/r/rooted_tree_topological_order_with_minimum_inversions.c`](../../../c/r/rooted_tree_topological_order_with_minimum_inversions.c) |
| C3 | [`c3/r/rooted_tree_topological_order_with_minimum_inversions.c3`](../../../c3/r/rooted_tree_topological_order_with_minimum_inversions.c3) |
| C++ | [`cpp/r/rooted_tree_topological_order_with_minimum_inversions.cpp`](../../../cpp/r/rooted_tree_topological_order_with_minimum_inversions.cpp) |
| Elisa | [`elisa/r/rooted_tree_topological_order_with_minimum_inversions.elisa`](../../../elisa/r/rooted_tree_topological_order_with_minimum_inversions.elisa) |
| Mojo | [`mojo/r/rooted_tree_topological_order_with_minimum_inversions.mojo`](../../../mojo/r/rooted_tree_topological_order_with_minimum_inversions.mojo) |
| Nim | [`nim/r/rooted_tree_topological_order_with_minimum_inversions.nim`](../../../nim/r/rooted_tree_topological_order_with_minimum_inversions.nim) |
| Odin | [`odin/r/rooted_tree_topological_order_with_minimum_inversions.odin`](../../../odin/r/rooted_tree_topological_order_with_minimum_inversions.odin) |
| Rust | [`rust/r/rooted_tree_topological_order_with_minimum_inversions.rs`](../../../rust/r/rooted_tree_topological_order_with_minimum_inversions.rs) |
| V | [`v/r/rooted_tree_topological_order_with_minimum_inversions.v`](../../../v/r/rooted_tree_topological_order_with_minimum_inversions.v) |
| Zig | [`zig/r/rooted_tree_topological_order_with_minimum_inversions.zig`](../../../zig/r/rooted_tree_topological_order_with_minimum_inversions.zig) |
