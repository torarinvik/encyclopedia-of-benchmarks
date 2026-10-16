# Bron–Kerbosch maximal cliques

Enumerate every maximal clique in a small undirected graph with the pivoted Bron–Kerbosch recursion.

## Contract

The `i64_array_scalar` input is a vertex count `n` followed by `n` adjacency bitmasks, for `0 <= n <= 5`. Bit `v` in row `u` indicates an edge from `u` to `v`; each row must fit in `n` bits, and off-diagonal edges must be symmetric. Diagonal bits are accepted and ignored, matching the source’s removal of self-edges. Malformed input returns `-1`.

The signed 64-bit result is a bitset of maximal cliques. A clique with vertex mask `m` sets result bit `m`. This preserves the complete clique set while normalizing the unordered `Set` and `HashSet` iteration order used by the Java source. The five-vertex limit keeps that exact set encoding within 32 result bits.

The pivot is selected from `P ∪ X` by greatest full graph degree, matching the pinned implementation; equal-degree pivots use the lowest vertex ID for deterministic traversal. Candidate vertices are visited in ascending order. The returned clique set is independent of either traversal order.

## Source

- Java [`BronKerbosch.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/BronKerbosch.java)

The source accepts a list of neighbor sets, drops self-edges from its copied graph, then applies pivoted recursion until both `P` and `X` are empty. This benchmark defines symmetric simple-graph inputs so the mathematical maximal-clique result has a shared meaning across ports.

## Workload and verification

[`workload.json`](workload.json) includes empty, complete, path, cycle, disconnected, and malformed graphs. The array-scalar verifier exhaustively covers every simple undirected graph through five vertices and compares the encoded output with a separate subset-enumeration oracle.

```sh
python3 benchmarks/verify_i64_array_scalar.py --algorithm bron_kerbosch --jobs 3 --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm bron_kerbosch --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/b/bron_kerbosch/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/b/bron_kerbosch.c`](../../../c/b/bron_kerbosch.c) |
| C3 | [`c3/b/bron_kerbosch.c3`](../../../c3/b/bron_kerbosch.c3) |
| C++ | [`cpp/b/bron_kerbosch.cpp`](../../../cpp/b/bron_kerbosch.cpp) |
| Elisa | [`elisa/b/bron_kerbosch.elisa`](../../../elisa/b/bron_kerbosch.elisa) |
| Nim | [`nim/b/bron_kerbosch.nim`](../../../nim/b/bron_kerbosch.nim) |
| Odin | [`odin/b/bron_kerbosch.odin`](../../../odin/b/bron_kerbosch.odin) |
| Rust | [`rust/b/bron_kerbosch.rs`](../../../rust/b/bron_kerbosch.rs) |
| V | [`v/b/bron_kerbosch.v`](../../../v/b/bron_kerbosch.v) |
| Zig | [`zig/b/bron_kerbosch.zig`](../../../zig/b/bron_kerbosch.zig) |
