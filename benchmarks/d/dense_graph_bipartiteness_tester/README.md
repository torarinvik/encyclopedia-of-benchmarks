# Dense-graph bipartiteness property tester

This package implements the dense-model property tester from Oded Goldreich and Dana Ron's *Encyclopedia of Algorithms* chapter “Testing Bipartiteness in the Dense-Graph Model,” DOI [`10.1007/978-1-4939-2864-4_702`](https://doi.org/10.1007/978-1-4939-2864-4_702). It samples vertices without replacement, queries all pairs in the induced sample, and accepts exactly when that sample is bipartite.

## Bounded contract

- ABI: `i64_array_bytes_output`; input is `[N,q,rowmask_0,...,rowmask_(N-1),draw_0,...,draw_(q-1)]`.
- `1 <= N <= 64`, `1 <= q <= min(N,16)`. Each row mask is a signed-i64 slot interpreted as its unsigned 64-bit bit pattern. Rows must describe a simple, undirected graph: no diagonal bits, symmetric adjacency, and no bits above `N-1` when `N<64`.
- At sample step `i`, `draw_i` must be in `[0,N-i)`. Starting with vertex IDs in ascending order, select `remaining[i+draw_i]` and swap it with `remaining[i]`. Independent uniform draws in these ranges produce a uniform sample without replacement; the input supplies the draws to make the trace reproducible.
- The tester queries every unordered pair in the selected sample, builds that induced graph, and performs BFS two-coloring. Output is `[accept_bit, q*(q-1)/2]` as two little-endian signed-i64 words. The second word is the number of adjacency-oracle queries. The query count is fixed even when the sample is non-bipartite because all pair queries are part of the profile.
- Maximum input is 82 words; output is exactly 16 bytes. Invalid input returns `-1`; null or short output returns `-2` without writes.
- `q` is explicit and fixed by the workload. The profile preserves the sampling and induced-sample decision operation but does not claim an epsilon-to-sample-size schedule, the chapter's soundness guarantee, or an asymptotic query bound. A supplied trace can accept a graph that is far from bipartite.

This package is distinct from exact whole-graph [bipartite recognition](../b/bipartite_graph_dfs/README.md): it selects a random vertex sample and queries only the induced sample. The supplied draw trace makes that randomized outer procedure observable and reproducible.

## Provenance and rights

Source attribution: Oded Goldreich and Dana Ron, “Testing Bipartiteness in the Dense-Graph Model,” *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_702`. The chapter and cited research remain copyrighted. This clean-room package copies no source code, prose, or figures and asserts no redistribution license for them. See [`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json)
- [primary BFS oracle](../../dense_graph_bipartiteness_tester_oracle.py)
- [independent exhaustive-coloring verifier oracle](../../dense_graph_bipartiteness_tester_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/t/dense_graph_bipartiteness_tester.c`](../../../c/t/dense_graph_bipartiteness_tester.c) |
| C3 | [`c3/t/dense_graph_bipartiteness_tester.c3`](../../../c3/t/dense_graph_bipartiteness_tester.c3) |
| C++ | [`cpp/t/dense_graph_bipartiteness_tester.cpp`](../../../cpp/t/dense_graph_bipartiteness_tester.cpp) |
| Elisa | [`elisa/t/dense_graph_bipartiteness_tester.elisa`](../../../elisa/t/dense_graph_bipartiteness_tester.elisa) |
| Nim | [`nim/t/dense_graph_bipartiteness_tester.nim`](../../../nim/t/dense_graph_bipartiteness_tester.nim) |
| Odin | [`odin/t/dense_graph_bipartiteness_tester.odin`](../../../odin/t/dense_graph_bipartiteness_tester.odin) |
| Rust | [`rust/t/dense_graph_bipartiteness_tester.rs`](../../../rust/t/dense_graph_bipartiteness_tester.rs) |
| V | [`v/t/dense_graph_bipartiteness_tester.v`](../../../v/t/dense_graph_bipartiteness_tester.v) |
| Zig | [`zig/t/dense_graph_bipartiteness_tester.zig`](../../../zig/t/dense_graph_bipartiteness_tester.zig) |
