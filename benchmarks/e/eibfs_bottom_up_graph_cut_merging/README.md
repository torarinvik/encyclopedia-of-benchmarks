# EIBFS adaptive bottom-up graph-cut merging

This bounded clean-room, PEIBFS-inspired profile combines Liu and Sun's adaptive
bottom-up block-merging strategy with Excesses IBFS (EIBFS) as its local
max-flow solver. It exercises initial block solves, deterministic merge
priority, component unions, and repeated EIBFS solves for enlarged components.
The profile is deterministic and sequential; it does not copy the original
parallel schedule.

## Contract

- ABI: `i64_array_scalar`, symbol `eibfs_bottom_up_graph_cut_merging`.
- Input: `[N,M,B,block_ids[N],source_caps[N],sink_caps[N],(u,v,cap_uv,cap_vu)*M]`.
- `2<=N<=6`, `0<=M<=6`, `1<=B<=min(N,4)`. Every block ID in `0..B-1`
  must occur. Nodes are `0..N-1`; source and sink are virtual terminals.
- Terminal and directed neighbor capacities are integers from 0 through 7.
  Self-loops are invalid; parallel and antiparallel arcs are allowed and summed.
- Valid input length is exactly `3+3N+4M`; maximum valid and parseable lengths
  are 45 and 46 words. A null input pointer returns -1 at both declared lengths
  0 and 46; malformed inputs return -1.
- Return the maximum source-to-sink flow, bounded by `6*7=42`.

## Fixed merge profile

Initially, each block is solved in ascending block ID with cross-block arcs
disabled. The bounded profile computes a canonical min-cut side for that block
by enumerating its at most 64 vertex masks; ties select the numerically smallest
source-side mask. Count each positive directed boundary half-arc whose endpoint
tags differ. Merge boundaries by descending potential, then ascending unordered
block-ID pair; the lower component ID becomes the union-find root. On each
merge, run EIBFS from scratch on the original capacities internal to the
enlarged component. Sum the most recent EIBFS value for each final component.

Each EIBFS solve receives only the component's original capacity graph, with
the component's vertices and two virtual terminals. For the bounds above, a
serialized local frame has at most eight vertices and 24 directed arc records,
matching the standalone EIBFS port bounds. A fresh EIBFS state is essential to
this profile: it does not carry an earlier pseudoflow's residual capacities
while dropping its excess/deficit balances or forests. This deterministic
restart schedule is a bounded PEIBFS-inspired composite, not a reproduction of
the original implementation's dynamic continuation.

Let `T_EIBFS(V,E)` denote the cost of one local EIBFS solve on `V` vertices and
`E` directed arc records. With `N` input vertices, `M` input edge records, and
`B` blocks, this profile makes at most `2B-1` local solves and takes
`O((2B-1) T_EIBFS(N+2, 2N+2M) + 2^N(N+M) + M log M)` time: the extra terms
cover canonical cut-mask enumeration and boundary scoring/order. It uses
`O((N+2)^2 + N + M + B)` space, including the dense EIBFS residual matrix.
Here `N<=6`, `M<=6`, and `B<=4`, so each local frame fits the eight-vertex,
24-arc EIBFS bounds.

This profile differs from the adjacent [`adaptive_bottom_up_graph_cut_merging`](../../a/adaptive_bottom_up_graph_cut_merging/README.md)
package, which uses Edmonds-Karp for its local solves. The fcBK catalog's
`liusun` entry uses BK; its `peibfs` entry uses EIBFS. Here, EIBFS handles every
local component solve, with fresh state at every merge. The fixed cut tags,
potential, and merge tie order make this single-call profile reproducible, but
it does not claim exact schedule parity or flow-state reuse from either
upstream parallel implementation.

The primary reference uses the EIBFS two-forest pseudoflow algorithm on each
component and exhaustive small-mask cuts only to choose deterministic merge
tags. The independent reference enumerates all `2^N` terminal cuts of the
complete graph directly.

## Provenance and rights

Liu and Sun introduced adaptive bottom-up graph-cut merging in [“Parallel
Graph-cuts by Adaptive Bottom-up Merging”](https://doi.org/10.1109/CVPR.2010.5539898).
The source inventory identifies PEIBFS as that merging strategy with EIBFS
instead of BK. EIBFS is described by Goldberg, Hed, Kaplan, Kohli, Tarjan, and
Werneck in [“Faster and More Dynamic Maximum Flow by Incremental Breadth-First
Search,” ESA 2015](https://www.microsoft.com/en-us/research/publication/faster-and-more-dynamic-maximum-flow-by-incremental-breadth-first-search/).
The [Jensen et al. review](https://arxiv.org/abs/2202.00418) and the
[fcBK source inventory](https://github.com/fcBK-maxflow/fcBK-benchmark) were
used to identify the component methods. Only algorithm descriptions were used;
no upstream source code or benchmark instances were copied. See [RIGHTS](RIGHTS.md)
and [`workload.json`](workload.json), plus the static package inventory at
[`benchmarks/check_eibfs_bottom_up_graph_cut_merging_package.py`](../../check_eibfs_bottom_up_graph_cut_merging_package.py).

| Language | Port |
|---|---|
| C | [c/e/eibfs_bottom_up_graph_cut_merging.c](../../../c/e/eibfs_bottom_up_graph_cut_merging.c) |
| C3 | [c3/e/eibfs_bottom_up_graph_cut_merging.c3](../../../c3/e/eibfs_bottom_up_graph_cut_merging.c3) |
| C++ | [cpp/e/eibfs_bottom_up_graph_cut_merging.cpp](../../../cpp/e/eibfs_bottom_up_graph_cut_merging.cpp) |
| Elisa | [elisa/e/eibfs_bottom_up_graph_cut_merging.elisa](../../../elisa/e/eibfs_bottom_up_graph_cut_merging.elisa) |
| Mojo | [mojo/e/eibfs_bottom_up_graph_cut_merging.mojo](../../../mojo/e/eibfs_bottom_up_graph_cut_merging.mojo) |
| Nim | [nim/e/eibfs_bottom_up_graph_cut_merging.nim](../../../nim/e/eibfs_bottom_up_graph_cut_merging.nim) |
| Odin | [odin/e/eibfs_bottom_up_graph_cut_merging.odin](../../../odin/e/eibfs_bottom_up_graph_cut_merging.odin) |
| Rust | [rust/e/eibfs_bottom_up_graph_cut_merging.rs](../../../rust/e/eibfs_bottom_up_graph_cut_merging.rs) |
| V | [v/e/eibfs_bottom_up_graph_cut_merging.v](../../../v/e/eibfs_bottom_up_graph_cut_merging.v) |
| Zig | [zig/e/eibfs_bottom_up_graph_cut_merging.zig](../../../zig/e/eibfs_bottom_up_graph_cut_merging.zig) |
