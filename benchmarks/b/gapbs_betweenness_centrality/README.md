# GAPBS Brandes betweenness centrality

This package is a bounded clean-room profile of the unweighted Brandes
betweenness-centrality kernel in GAPBS. It is distinct from the local
[`graph_centrality`](../../g/graph_centrality/README.md) package, which computes
minimum eccentricity and harmonic closeness through Floyd–Warshall.

## Contract

- Exported symbol: `gapbs_betweenness_centrality` (`i64_array_scalar`).
- Input: `[n, source_count, source_0, ..., source_(k-1), A[0,0], ..., A[n-1,n-1]]`.
- `3 <= n <= 8`, `1 <= source_count <= n`; source IDs are unique integers in
  `[0,n)`. The final `n*n` values are a row-major adjacency matrix of a simple,
  undirected, unweighted graph (`0` or `1`, symmetric, zero diagonal).
- The bounded adapter supplies the ordered source list explicitly in place of
  GAPBS `SourcePicker`; it processes each listed source once, in list order.
  Disconnected graphs are accepted. The call is invalid if the accumulated
  maximum dependency score is zero, because GAPBS normalization would divide
  by zero in that case.
- For each source, a FIFO BFS computes shortest-path depths and path counts.
  Vertices are traversed in ascending ID order. A reverse-depth Brandes pass
  accumulates `delta[u] += (sigma[u]/sigma[v]) * (1 + delta[v])` for each
  shortest-path successor `v`; the source implementation stores `ScoreT` as
  binary32 and `CountT` as binary64. This profile rounds dependency and
  accumulated-score stores to binary32 after each source-order update. Like
  the pinned kernel, it adds each source's dependency score for the source
  vertex itself as well as for other vertices.
- After all sources, scores are divided by the largest score using binary32.
  Each normalized score is rounded to the nearest thousandth, with positive
  half values rounded upward. The result is `sum((vertex_id+1)*qscore)`.
  The maximum result is 36,000.
- Return `-1` for null, malformed, out-of-range, asymmetric, self-looped,
  nonbinary, duplicate-source, or zero-maximum-score input.

The scalar checksum keeps the score calculation observable while avoiding a
language-specific float-array ABI. The fixed source list and quantization are
profile boundaries; this package does not model GAPBS graph generation,
parallel scheduling, source sampling, or command-line output.

## Source and rights

Behavior reference: [`src/bc.cc::PBFS` and `Brandes`](https://github.com/sbeamer/gapbs/blob/b5e3e19c2845f22fb338f4a4bc4b1ccee861d026/src/bc.cc), pinned to GAPBS commit
`b5e3e19c2845f22fb338f4a4bc4b1ccee861d026`. The ports are independent
implementations of the algorithm and do not copy upstream source text or
comments. The pinned repository is under BSD-3-Clause; its complete notice is
included in [`LICENSE.txt`](LICENSE.txt).

The independent oracle enumerates shortest paths and distributes one unit
across each target's shortest paths. Workload cases and expected checksums are
in [`workload.json`](workload.json); the oracle is
[`gapbs_betweenness_centrality_oracle.py`](../../gapbs_betweenness_centrality_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/gapbs_betweenness_centrality.c`](../../../c/b/gapbs_betweenness_centrality.c) |
| C3 | [`c3/b/gapbs_betweenness_centrality.c3`](../../../c3/b/gapbs_betweenness_centrality.c3) |
| C++ | [`cpp/b/gapbs_betweenness_centrality.cpp`](../../../cpp/b/gapbs_betweenness_centrality.cpp) |
| Elisa | [`elisa/b/gapbs_betweenness_centrality.elisa`](../../../elisa/b/gapbs_betweenness_centrality.elisa) |
| Nim | [`nim/b/gapbs_betweenness_centrality.nim`](../../../nim/b/gapbs_betweenness_centrality.nim) |
| Odin | [`odin/b/gapbs_betweenness_centrality.odin`](../../../odin/b/gapbs_betweenness_centrality.odin) |
| Rust | [`rust/b/gapbs_betweenness_centrality.rs`](../../../rust/b/gapbs_betweenness_centrality.rs) |
| V | [`v/b/gapbs_betweenness_centrality.v`](../../../v/b/gapbs_betweenness_centrality.v) |
| Zig | [`zig/b/gapbs_betweenness_centrality.zig`](../../../zig/b/gapbs_betweenness_centrality.zig) |
