# Exact treewidth by bounded elimination-order enumeration

This package computes treewidth exactly by enumerating every vertex elimination order and selecting the one with minimum width, using the chapter's equivalence between treewidth and minimum elimination width. It implements the bounded combinatorial definition from Hans L. Bodlaender's *Encyclopedia of Algorithms* chapter “Treewidth of Graphs,” DOI [`10.1007/978-1-4939-2864-4_431`](https://doi.org/10.1007/978-1-4939-2864-4_431).

## Bounded contract

- ABI: `i64_array_bytes_output`; input is `[n,m,u0,v0,...]` for a simple undirected graph on vertices `0..n-1`.
- `1 <= n <= 8`, `0 <= m <= 28`, and each edge satisfies `0 <= u < v < n`; duplicate edges and malformed lengths are invalid.
- For each permutation in lexicographic order, simulate elimination: measure the active degree of the next vertex, make its active neighbors a clique, then remove it. Return the minimum maximum degree over all permutations. If multiple orders attain it, return the lexicographically first order.
- Output is `[treewidth,elimination_order[0..n-1]]` in little-endian signed 64-bit words, at most 72 bytes. Invalid input returns `-1`; null or short output returns `-2` without writes.
- This is an exact exhaustive profile for small graphs. It is distinct from [minimum-degree](../treewidth_min_degree_elimination/README.md) and [minimum-fill](../treewidth_min_fill_elimination/README.md), which are greedy upper-bound heuristics. The package does not implement Fomin–Villanger's cited `O(1.7549^n)` algorithm or claim that time bound.

## Provenance and rights

Source attribution: Hans L. Bodlaender, “Treewidth of Graphs,” *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_431`. The chapter and cited papers remain copyrighted. This package copies no code, prose, or figures; its ports are clean-room implementations of the chapter's elimination characterization by exhaustive enumeration. No source-code redistribution license is asserted. See [`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json)
- [primary matrix oracle](../../treewidth_exact_elimination_order_oracle.py)
- [independent bitset verifier oracle](../../treewidth_exact_elimination_order_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/t/treewidth_exact_elimination_order.c`](../../../c/t/treewidth_exact_elimination_order.c) |
| C3 | [`c3/t/treewidth_exact_elimination_order.c3`](../../../c3/t/treewidth_exact_elimination_order.c3) |
| C++ | [`cpp/t/treewidth_exact_elimination_order.cpp`](../../../cpp/t/treewidth_exact_elimination_order.cpp) |
| Elisa | [`elisa/t/treewidth_exact_elimination_order.elisa`](../../../elisa/t/treewidth_exact_elimination_order.elisa) |
| Nim | [`nim/t/treewidth_exact_elimination_order.nim`](../../../nim/t/treewidth_exact_elimination_order.nim) |
| Odin | [`odin/t/treewidth_exact_elimination_order.odin`](../../../odin/t/treewidth_exact_elimination_order.odin) |
| Rust | [`rust/t/treewidth_exact_elimination_order.rs`](../../../rust/t/treewidth_exact_elimination_order.rs) |
| V | [`v/t/treewidth_exact_elimination_order.v`](../../../v/t/treewidth_exact_elimination_order.v) |
| Zig | [`zig/t/treewidth_exact_elimination_order.zig`](../../../zig/t/treewidth_exact_elimination_order.zig) |
