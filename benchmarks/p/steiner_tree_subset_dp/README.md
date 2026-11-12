# Exact graph Steiner tree by terminal-subset DP

This benchmark finds a minimum-weight connected subgraph that joins a selected set of terminals in a weighted undirected graph. It uses the Dreyfus–Wagner subset dynamic program: merge complementary terminal subsets at a root vertex, then propagate each subset state along graph edges with multi-source shortest paths.

The local [`steiner_tree_gain_greedy`](../steiner_tree_gain_greedy/README.md) benchmark solves a different problem: it greedily chooses from an explicitly supplied family of full components using a gain potential. This package computes the exact optimum over an explicitly supplied graph.

## Contract

The exported symbol is `steiner_tree_subset_dp` with the `i64_array_scalar` ABI. Input is `[N,M,K,terminal_0,...,terminal_(K-1),(u,v,w)*M]`. `1<=N<=8`, `0<=M<=14`, and `1<=K<=min(N,5)`. Terminals must be distinct. Each edge is an undirected simple edge encoded canonically with `0<=u<v<N`; edge weights are integers in `[0,1000]`. Edge order is arbitrary. Exact input length is `3+K+3*M`, at most 50 signed i64 values.

Malformed input returns `-1`. A valid input whose terminals are disconnected returns `-2`. Otherwise the result is the exact minimum total edge weight of a connected subgraph containing every terminal; a single terminal has cost zero. Nonnegative weights permit deleting cycles from an optimal subgraph without increasing its cost.

The primary oracle uses terminal-subset merging and Dijkstra relaxation. The independent oracle enumerates all edge subsets and checks terminal connectivity by disjoint sets. The bounded primary complexity is `O(3^K N + 2^K(N^2+M))` with a fixed-array shortest-path selector; the independent oracle takes `O(2^M(N+M))`.

## Provenance and rights

The [OI Wiki Steiner Tree article](https://oi-wiki.org/graph/steiner-tree/) describes the exact graph problem and the subset-DP merge and edge-relaxation recurrences. OI Wiki states that its content is available under CC BY-SA 4.0 and SATA. This package uses only that high-level algorithm description; its contract, fixtures, oracles, and ten ports are clean-room work.

See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the [primary oracle](../../steiner_tree_subset_dp_oracle.py), the [independent verifier](../../steiner_tree_subset_dp_verifier_oracle.py), and the package-local static [inventory checker](../../check_steiner_tree_subset_dp_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/s/steiner_tree_subset_dp.c`](../../../c/s/steiner_tree_subset_dp.c) |
| C3 | [`c3/s/steiner_tree_subset_dp.c3`](../../../c3/s/steiner_tree_subset_dp.c3) |
| C++ | [`cpp/s/steiner_tree_subset_dp.cpp`](../../../cpp/s/steiner_tree_subset_dp.cpp) |
| Elisa | [`elisa/s/steiner_tree_subset_dp.elisa`](../../../elisa/s/steiner_tree_subset_dp.elisa) |
| Mojo | [`mojo/s/steiner_tree_subset_dp.mojo`](../../../mojo/s/steiner_tree_subset_dp.mojo) |
| Nim | [`nim/s/steiner_tree_subset_dp.nim`](../../../nim/s/steiner_tree_subset_dp.nim) |
| Odin | [`odin/s/steiner_tree_subset_dp.odin`](../../../odin/s/steiner_tree_subset_dp.odin) |
| Rust | [`rust/s/steiner_tree_subset_dp.rs`](../../../rust/s/steiner_tree_subset_dp.rs) |
| V | [`v/s/steiner_tree_subset_dp.v`](../../../v/s/steiner_tree_subset_dp.v) |
| Zig | [`zig/s/steiner_tree_subset_dp.zig`](../../../zig/s/steiner_tree_subset_dp.zig) |
