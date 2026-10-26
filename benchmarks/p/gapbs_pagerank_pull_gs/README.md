# GAPBS PageRank pull Gauss–Seidel profile

This package implements a bounded clean-room profile of GAPBS `PageRankPullGS`. It performs in-place Gauss–Seidel updates: after a destination rank is updated, its outgoing contribution is refreshed immediately, so later destination vertices in that iteration can consume the new value. The local `page_rank` and `page_rank_java` profiles update synchronously from a separate next-rank array and therefore have different iteration semantics.

## Contract

- Exported symbol: `gapbs_pagerank_pull_gs` (`i64_array_scalar`).
- Input is `[n, iteration_count, A[0,0], ..., A[n-1,n-1]]`, where `A` is a row-major directed adjacency matrix and `A[u,v] = 1` represents edge `u → v`.
- Bounds are `2 <= n <= 8`, `0 <= iteration_count <= 20`, binary entries, and a zero diagonal. Every row must have at least one outgoing edge; graphs with dangling vertices are rejected because the source initializes `rank/outdegree` without a dangling-node branch.
- Initialize each binary32 score to `1/n` and each outgoing contribution to `score/outdegree`. Damping is binary32 `0.85`; the base score is binary32 `(1.0f - damping)/n`.
- For every requested iteration, visit targets in ascending vertex ID order. Sum incoming outgoing-contributions in ascending source ID order, update the target score, and immediately replace its outgoing contribution. This is the source's pull Gauss–Seidel order, not a Jacobi/synchronous update.
- Epsilon is fixed at zero. Because the pinned source stops only when `error < epsilon`, this profile always runs exactly the requested number of iterations.
- Return `floor(100 * sum((vertex_id + 1) * score[vertex_id]) + 0.5)`. This integer checksum makes the binary32 state observable through the shared scalar ABI. Invalid input returns `-1`.

The profile omits graph generation and loading, OpenMP scheduling, logging, top-k display, the source verifier, and convergence-error accumulation. The independent oracle explicitly rounds every score and contribution operation to IEEE binary32. Workload inputs and expected checksums are in [`workload.json`](workload.json); the oracle is [`gapbs_pagerank_pull_gs_oracle.py`](../../gapbs_pagerank_pull_gs_oracle.py).

## Source and rights

Behavior reference: [`src/pr.cc::PageRankPullGS`](https://github.com/sbeamer/gapbs/blob/b5e3e19c2845f22fb338f4a4bc4b1ccee861d026/src/pr.cc), pinned to GAPBS commit `b5e3e19c2845f22fb338f4a4bc4b1ccee861d026`. Its source header attributes copyright to the Regents of the University of California and points to `LICENSE.txt`; the repository license is BSD-3-Clause. These implementations were independently written from the algorithm description and do not copy upstream code or comments. The complete upstream notice is included in [`LICENSE.txt`](LICENSE.txt).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/gapbs_pagerank_pull_gs.c`](../../../c/p/gapbs_pagerank_pull_gs.c) |
| C3 | [`c3/p/gapbs_pagerank_pull_gs.c3`](../../../c3/p/gapbs_pagerank_pull_gs.c3) |
| C++ | [`cpp/p/gapbs_pagerank_pull_gs.cpp`](../../../cpp/p/gapbs_pagerank_pull_gs.cpp) |
| Elisa | [`elisa/p/gapbs_pagerank_pull_gs.elisa`](../../../elisa/p/gapbs_pagerank_pull_gs.elisa) |
| Nim | [`nim/p/gapbs_pagerank_pull_gs.nim`](../../../nim/p/gapbs_pagerank_pull_gs.nim) |
| Odin | [`odin/p/gapbs_pagerank_pull_gs.odin`](../../../odin/p/gapbs_pagerank_pull_gs.odin) |
| Rust | [`rust/p/gapbs_pagerank_pull_gs.rs`](../../../rust/p/gapbs_pagerank_pull_gs.rs) |
| V | [`v/p/gapbs_pagerank_pull_gs.v`](../../../v/p/gapbs_pagerank_pull_gs.v) |
| Zig | [`zig/p/gapbs_pagerank_pull_gs.zig`](../../../zig/p/gapbs_pagerank_pull_gs.zig) |
