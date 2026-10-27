# Pruning minimum spanning tree for multicast

This package covers the source-defined PMST tree-construction subcase in Weizhao Wang, Xiang-Yang Li, and Yu Wang's *Encyclopedia of Algorithms* chapter “Truthful Multicast,” DOI [`10.1007/978-1-4939-2864-4_437`](https://doi.org/10.1007/978-1-4939-2864-4_437). The chapter defines PMST by building a minimum spanning tree, rooting it at the sender, and pruning every subtree that contains no receiver.

## Bounded contract

- ABI: `i64_array_bytes_output`; input is `[n,m,sender,receiver_count, edges[3m], receivers[r]]`, where each edge is `(u,v,weight)`.
- `2<=n<=8`, `n-1<=m<=28`, and `1<=r<n`. The graph must be connected and simple; endpoints use `u<v`; edge records and receiver IDs are strictly increasing by their endpoint/ID ordering. Weights are integers in `[1,100]`. The sender is not a receiver.
- Kruskal uses `(weight,u,v)` to break ties, then the resulting MST is rooted at the sender. The output is the union of sender-to-receiver paths, represented as `[edge_count,(u,v,weight)...]` with edges sorted by `(u,v)`. Maximum input is 95 words and output is 176 bytes.
- This package covers the PMST tree only. It does not implement the chapter's non-VCG payment mechanism or claim truthfulness/payment coverage.

## Provenance and rights

Source attribution: Weizhao Wang, Xiang-Yang Li, and Yu Wang, “Truthful Multicast,” *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_437`. The chapter expressly defines PMST as MST followed by rooting and pruning. This is a clean-room implementation; it reproduces no chapter prose, code, or figures, and no source-code license is asserted. See [`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json)
- [primary Kruskal oracle](../../truthful_multicast_pmst_tree_oracle.py)
- [independent Prim verifier](../../truthful_multicast_pmst_tree_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/t/truthful_multicast_pmst_tree.c`](../../../c/t/truthful_multicast_pmst_tree.c) |
| C3 | [`c3/t/truthful_multicast_pmst_tree.c3`](../../../c3/t/truthful_multicast_pmst_tree.c3) |
| C++ | [`cpp/t/truthful_multicast_pmst_tree.cpp`](../../../cpp/t/truthful_multicast_pmst_tree.cpp) |
| Elisa | [`elisa/t/truthful_multicast_pmst_tree.elisa`](../../../elisa/t/truthful_multicast_pmst_tree.elisa) |
| Nim | [`nim/t/truthful_multicast_pmst_tree.nim`](../../../nim/t/truthful_multicast_pmst_tree.nim) |
| Odin | [`odin/t/truthful_multicast_pmst_tree.odin`](../../../odin/t/truthful_multicast_pmst_tree.odin) |
| Rust | [`rust/t/truthful_multicast_pmst_tree.rs`](../../../rust/t/truthful_multicast_pmst_tree.rs) |
| V | [`v/t/truthful_multicast_pmst_tree.v`](../../../v/t/truthful_multicast_pmst_tree.v) |
| Zig | [`zig/t/truthful_multicast_pmst_tree.zig`](../../../zig/t/truthful_multicast_pmst_tree.zig) |
