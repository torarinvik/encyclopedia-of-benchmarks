# Union-find with noncommutative matrix potential

This benchmark maintains relative potentials in `SL(2, F_998244353)` using a
weighted disjoint-set union structure. Matrix multiplication is not
commutative, so the order of potential composition and inversion is part of
the algorithm.

## Contract

For an update, the official task adds the equation `a[u] = a[v] * X (mod M)`.
It is accepted with result `1` when consistent with all earlier accepted
equations, otherwise rejected with result `0`. A query returns
`inverse(a[v]) * a[u]` when determined, or `-1` if the vertices are
disconnected. Here `M = 998244353` and each supplied 2×2 matrix has determinant
one modulo `M`.

The bounded ABI uses `[N, Q, (type, u, v, m00, m01, m10, m11)...]`, with a
fixed seven-value record per operation. Updates use all four row-major matrix
entries. Queries set the four unused matrix entries to zero. The profile limits
`1 <= N <= 32` and `1 <= Q <= 64`. Indices must be in `[0,N)`, and update
matrices must have entries in `[0,M)` and determinant one modulo `M`.

Each operation emits four signed 64-bit little-endian values. An accepted or
rejected update emits `[1,0,0,0]` or `[0,0,0,0]`; a connected query emits the
row-major relative matrix; a disconnected query emits `[-1,-1,-1,-1]`. Invalid
input returns `-1`. A null or undersized output buffer returns `-2` without
writing. The implementation uses path compression and union by size. Each
parent edge stores a right-relative matrix; path compression composes the
parent potential before the child potential, preserving noncommutative order.

## Distinctness

The adjacent [`unionfind_with_potential`](../unionfind_with_potential/README.md)
benchmark is restricted to additive scalar potentials modulo `M`, where
composition commutes. This package uses invertible 2×2 matrices and must
preserve matrix order when composing potentials and applying inverses. The
ordinary [`union_find`](../union_find/README.md) package has no potentials.

Official contract: [Library Checker — Unionfind with Potential (Non-Commutative Group)](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/unionfind_with_potential_non_commutative_group/task.md)
with limits from its [info.toml](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/unionfind_with_potential_non_commutative_group/info.toml).

## Workload and oracle

[`workload.json`](workload.json) includes ordered matrix composition, a
disconnected query, invalid determinants, and output-capacity errors. The
independent [`benchmarks/unionfind_with_potential_non_commutative_group_oracle.py`](../../unionfind_with_potential_non_commutative_group_oracle.py)
uses graph traversal over accepted matrix equations rather than a DSU.

## Implementations

| Language | Port |
|---|---|
| C | [`c/u/unionfind_with_potential_non_commutative_group.c`](../../../c/u/unionfind_with_potential_non_commutative_group.c) |
| C3 | [`c3/u/unionfind_with_potential_non_commutative_group.c3`](../../../c3/u/unionfind_with_potential_non_commutative_group.c3) |
| C++ | [`cpp/u/unionfind_with_potential_non_commutative_group.cpp`](../../../cpp/u/unionfind_with_potential_non_commutative_group.cpp) |
| Elisa | [`elisa/u/unionfind_with_potential_non_commutative_group.elisa`](../../../elisa/u/unionfind_with_potential_non_commutative_group.elisa) |
| Nim | [`nim/u/unionfind_with_potential_non_commutative_group.nim`](../../../nim/u/unionfind_with_potential_non_commutative_group.nim) |
| Odin | [`odin/u/unionfind_with_potential_non_commutative_group.odin`](../../../odin/u/unionfind_with_potential_non_commutative_group.odin) |
| Rust | [`rust/u/unionfind_with_potential_non_commutative_group.rs`](../../../rust/u/unionfind_with_potential_non_commutative_group.rs) |
| V | [`v/u/unionfind_with_potential_non_commutative_group.v`](../../../v/u/unionfind_with_potential_non_commutative_group.v) |
| Zig | [`zig/u/unionfind_with_potential_non_commutative_group.zig`](../../../zig/u/unionfind_with_potential_non_commutative_group.zig) |
| Mojo | [`mojo/u/unionfind_with_potential_non_commutative_group.mojo`](../../../mojo/u/unionfind_with_potential_non_commutative_group.mojo) |
