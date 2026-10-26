# Treewidth: minimum-degree elimination heuristic

This package implements the minimum-degree heuristic described in Hans L. Bodlaender's *Encyclopedia of Algorithms* chapter “Treewidth of Graphs,” DOI [`10.1007/978-1-4939-2864-4_431`](https://doi.org/10.1007/978-1-4939-2864-4_431). At each step it chooses a remaining vertex of minimum degree, fills its remaining neighborhood into a clique, and eliminates it.

## Bounded contract

- ABI: `i64_array_bytes_output`; input is `[n,m,u0,v0,...]`, an undirected simple graph on vertex IDs `0..n-1`.
- `n` is 1–16. Each edge must satisfy `0 <= u < v < n`; duplicates, loops, and malformed lengths are invalid.
- Ties between equal-degree vertices select the smallest vertex ID. When adding fill edges, neighbors are visited in ascending ID order; each new edge is recorded as `(smaller_id,larger_id)` in the order it is introduced.
- The output is `[width,elimination_order[0..n-1],fill_edge_count,u0,v0,...]`. `width` is the maximum degree at elimination time, so this heuristic's chordal completion gives a treewidth upper bound. The ordering and fill list make the heuristic result observable.
- Maximum output is 2064 bytes (n=16 and 120 recorded fill edges). Invalid input returns `-1`; null or short output returns `-2` without writes.

The source chapter distinguishes the minimum-degree heuristic from the exact treewidth problem. This package does **not** claim to compute exact treewidth or recognize all graphs of a requested width; it benchmarks the specific source-described heuristic with deterministic tie-breaking. No local graph package implements this elimination-and-fill recurrence.

## Provenance and rights

The source is Hans L. Bodlaender, “Treewidth of Graphs,” DOI `10.1007/978-1-4939-2864-4_431`. The chapter describes the heuristic and summarizes several underlying papers. This is a clean-room implementation of the mathematical rule; no copyrighted chapter prose or upstream source code is copied. See [`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json)
- [`primary oracle`](../../treewidth_min_degree_elimination_oracle.py)
- [`independent bitset verifier oracle`](../../treewidth_min_degree_elimination_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/t/treewidth_min_degree_elimination.c`](../../../c/t/treewidth_min_degree_elimination.c) |
| C3 | [`c3/t/treewidth_min_degree_elimination.c3`](../../../c3/t/treewidth_min_degree_elimination.c3) |
| C++ | [`cpp/t/treewidth_min_degree_elimination.cpp`](../../../cpp/t/treewidth_min_degree_elimination.cpp) |
| Elisa | [`elisa/t/treewidth_min_degree_elimination.elisa`](../../../elisa/t/treewidth_min_degree_elimination.elisa) |
| Nim | [`nim/t/treewidth_min_degree_elimination.nim`](../../../nim/t/treewidth_min_degree_elimination.nim) |
| Odin | [`odin/t/treewidth_min_degree_elimination.odin`](../../../odin/t/treewidth_min_degree_elimination.odin) |
| Rust | [`rust/t/treewidth_min_degree_elimination.rs`](../../../rust/t/treewidth_min_degree_elimination.rs) |
| V | [`v/t/treewidth_min_degree_elimination.v`](../../../v/t/treewidth_min_degree_elimination.v) |
| Zig | [`zig/t/treewidth_min_degree_elimination.zig`](../../../zig/t/treewidth_min_degree_elimination.zig) |
