# Adaptive bottom-up graph-cut merging

This package is a bounded clean-room profile of Liu and Sun's adaptive
bottom-up graph-cut merging strategy. It exercises the block split, independent
block solves, adaptive boundary merge priority, boundary restoration, and
incremental residual augmentation. It is a deterministic single-call profile;
it does not reproduce the original parallel schedule or claim to reproduce the
original paper's exact tie behavior.

## Contract

- ABI: `i64_array_scalar`, symbol `adaptive_bottom_up_graph_cut_merging`.
- Input: `[N,M,B,block_ids[N],source_caps[N],sink_caps[N],(u,v,cap_uv,cap_vu)*M]`.
- `2<=N<=8`, `0<=M<=16`, `1<=B<=min(N,4)`. Every block ID in `0..B-1`
  must occur. Nodes are `0..N-1`; source and sink are virtual terminals.
- Terminal and directed neighbor capacities are integers from 0 through 7.
  Self-loops are invalid; parallel and antiparallel arcs are allowed. A record
  with both directed capacities zero is treated as an absent edge and does not
  create a block boundary for merge ordering.
- Valid input length is exactly `3+3N+4M`; maximum valid and parseable lengths
  are 91 and 92 words. Invalid or null input returns `-1`.
- Return the maximum flow, bounded by `8*7=56`.

## Fixed merge profile

Phase one solves each block in ascending block ID with cross-block arcs
disabled. A vertex's phase-one residual tag is source-reachable, sink-co-
reachable, or unvisited. Each unordered block boundary gets a static potential
score: count the positive directed half-arcs whose endpoint tags differ. The
score is an explicit bounded proxy for new augmenting-path activations, based
on the paper/review description and the MIT reimplementation's activation
test. The profile chooses boundaries by descending static potential score and
then ascending unordered block-ID pair. When components merge, the lower
component ID is the root; all boundary capacities internal to that component
are restored together.

The residual flow is incrementally augmented after each merge using
Edmonds–Karp with ascending node scans. The paper uses Boykov–Kolmogorov and
reuses its search trees; this benchmark profile uses a simpler inner solver so
the block/merge method has a compact bounded contract across all ten languages.
It does not claim byte-for-byte or exact-tie reproduction of Liu and Sun's
closed paper implementation.

## Provenance and rights

Liu and Sun, [“Parallel Graph-cuts by Adaptive Bottom-up Merging”](https://doi.org/10.1109/CVPR.2010.5539898), introduced the strategy. The later
[Jensen et al. review](https://arxiv.org/abs/2202.00418) summarizes the phases
and the augmenting-path-potential merge heuristic. The authors' later
[MIT reimplementation](https://github.com/patmjen/maxflow_algorithms/blob/master/reimpls/liusun.h)
informs the explicit potential-count tie profile. The code here is independently
written from these descriptions; no upstream source or benchmark instance is
copied. See [RIGHTS](RIGHTS.md).

| Language | Port |
|---|---|
| C | [c/a/adaptive_bottom_up_graph_cut_merging.c](../../../c/a/adaptive_bottom_up_graph_cut_merging.c) |
| C3 | [c3/a/adaptive_bottom_up_graph_cut_merging.c3](../../../c3/a/adaptive_bottom_up_graph_cut_merging.c3) |
| C++ | [cpp/a/adaptive_bottom_up_graph_cut_merging.cpp](../../../cpp/a/adaptive_bottom_up_graph_cut_merging.cpp) |
| Elisa | [elisa/a/adaptive_bottom_up_graph_cut_merging.elisa](../../../elisa/a/adaptive_bottom_up_graph_cut_merging.elisa) |
| Mojo | [mojo/a/adaptive_bottom_up_graph_cut_merging.mojo](../../../mojo/a/adaptive_bottom_up_graph_cut_merging.mojo) |
| Nim | [nim/a/adaptive_bottom_up_graph_cut_merging.nim](../../../nim/a/adaptive_bottom_up_graph_cut_merging.nim) |
| Odin | [odin/a/adaptive_bottom_up_graph_cut_merging.odin](../../../odin/a/adaptive_bottom_up_graph_cut_merging.odin) |
| Rust | [rust/a/adaptive_bottom_up_graph_cut_merging.rs](../../../rust/a/adaptive_bottom_up_graph_cut_merging.rs) |
| V | [v/a/adaptive_bottom_up_graph_cut_merging.v](../../../v/a/adaptive_bottom_up_graph_cut_merging.v) |
| Zig | [zig/a/adaptive_bottom_up_graph_cut_merging.zig](../../../zig/a/adaptive_bottom_up_graph_cut_merging.zig) |
