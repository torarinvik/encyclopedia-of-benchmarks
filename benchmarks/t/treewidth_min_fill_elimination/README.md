# Treewidth: minimum-fill-in elimination heuristic

This package implements the minimum-fill-in heuristic described in Hans L. Bodlaender's *Encyclopedia of Algorithms* chapter “Treewidth of Graphs,” DOI [`10.1007/978-1-4939-2864-4_431`](https://doi.org/10.1007/978-1-4939-2864-4_431). At each step it chooses a remaining vertex whose neighborhood needs the fewest added edges to become a clique, adds those fill edges, and eliminates the vertex.

## Bounded contract

- ABI: `i64_array_bytes_output`; input is `[n,m,u0,v0,...]`, an undirected simple graph on vertex IDs `0..n-1`.
- `n` is 1–16. Each edge must satisfy `0 <= u < v < n`; duplicates, loops, and malformed lengths are invalid.
- The score is the number of currently missing edges among an active vertex's active neighbors. Ties select the smallest vertex ID. New fill edges are visited and recorded in ascending neighbor-pair order as `(smaller_id,larger_id)`.
- Output is `[width,elimination_order[0..n-1],fill_edge_count,u0,v0,...]`. `width` is the maximum active degree at elimination time and is an upper bound from the resulting chordal completion, not exact treewidth. The fill-edge list exposes the elimination rule's changes.
- The maximum output is 2064 bytes. Invalid input returns `-1`; null or short output returns `-2` without writes.

The source chapter distinguishes the minimum-fill heuristic from exact treewidth recognition. The profile is separate from [treewidth_min_degree_elimination](../treewidth_min_degree_elimination/README.md): it minimizes missing neighbor-neighbor edges, not active degree. Neither profile claims exact treewidth.

## Provenance and rights

The source is Hans L. Bodlaender, “Treewidth of Graphs,” DOI `10.1007/978-1-4939-2864-4_431`. The chapter describes the minimum-fill heuristic and summarizes several underlying papers. These ports are clean-room implementations of the source's mathematical rule; no copyrighted prose or upstream code is copied. See [`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json)
- [`primary matrix oracle`](../../treewidth_min_fill_elimination_oracle.py)
- [`independent bitset verifier oracle`](../../treewidth_min_fill_elimination_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/t/treewidth_min_fill_elimination.c`](../../../c/t/treewidth_min_fill_elimination.c) |
| C3 | [`c3/t/treewidth_min_fill_elimination.c3`](../../../c3/t/treewidth_min_fill_elimination.c3) |
| C++ | [`cpp/t/treewidth_min_fill_elimination.cpp`](../../../cpp/t/treewidth_min_fill_elimination.cpp) |
| Elisa | [`elisa/t/treewidth_min_fill_elimination.elisa`](../../../elisa/t/treewidth_min_fill_elimination.elisa) |
| Nim | [`nim/t/treewidth_min_fill_elimination.nim`](../../../nim/t/treewidth_min_fill_elimination.nim) |
| Odin | [`odin/t/treewidth_min_fill_elimination.odin`](../../../odin/t/treewidth_min_fill_elimination.odin) |
| Rust | [`rust/t/treewidth_min_fill_elimination.rs`](../../../rust/t/treewidth_min_fill_elimination.rs) |
| V | [`v/t/treewidth_min_fill_elimination.v`](../../../v/t/treewidth_min_fill_elimination.v) |
| Zig | [`zig/t/treewidth_min_fill_elimination.zig`](../../../zig/t/treewidth_min_fill_elimination.zig) |
