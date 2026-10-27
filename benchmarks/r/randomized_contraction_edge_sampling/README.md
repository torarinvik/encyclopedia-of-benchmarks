# Randomized contraction edge-sampling phase

This profile implements one source-defined phase from “Randomized
Contraction,” DOI
[`10.1007/978-1-4939-2864-4_764`](https://doi.org/10.1007/978-1-4939-2864-4_764):
independently contract each edge with probability one half. A supplied bit
per edge records the outcome of one deterministic replay of the random
choices. The profile computes the transitive contraction components and
reports the minimum-index vertex representative for each original vertex.

Input is `[n,m,(u,v,contract_bit)...]`, with `2 <= n <= 16`,
`n-1 <= m <= 24`, canonical simple undirected edges `0 <= u < v < n`, and
`contract_bit` in `{0,1}`. The input graph must be connected. The maximum input
length is 74 signed 64-bit integers. Output is one little-endian signed i32
representative per vertex, for at most 64 bytes. Invalid input returns `-1`;
null output or insufficient capacity returns `-2` without writing.

This is a contraction-phase trace only. It does not implement the chapter's
problem-specific good-separation search, multiway-cut recursion, high-
connectivity solver, full FPT algorithm, or a success-probability claim. It is
not Karger's complete minimum-cut algorithm.

| Language | Port |
|---|---|
| C | `c/r/randomized_contraction_edge_sampling.c` |
| C3 | `c3/r/randomized_contraction_edge_sampling.c3` |
| C++ | `cpp/r/randomized_contraction_edge_sampling.cpp` |
| Elisa | `elisa/r/randomized_contraction_edge_sampling.elisa` |
| Nim | `nim/r/randomized_contraction_edge_sampling.nim` |
| Odin | `odin/r/randomized_contraction_edge_sampling.odin` |
| Rust | `rust/r/randomized_contraction_edge_sampling.rs` |
| V | `v/r/randomized_contraction_edge_sampling.v` |
| Zig | `zig/r/randomized_contraction_edge_sampling.zig` |
