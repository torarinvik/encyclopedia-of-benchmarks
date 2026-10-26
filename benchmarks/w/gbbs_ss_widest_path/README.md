# GBBS single-source widest path

This package implements a bounded, deterministic profile of ParAlg/GBBS's
`SSWidestPath` kernel. For each vertex it returns the greatest bottleneck
capacity among directed paths from the chosen source, where a path's capacity
is the minimum edge capacity on that path. The path algebra is max-min, so
this is distinct from shortest paths such as Dijkstra, Bellman–Ford, and
delta-stepping.

## Contract

- Exported symbol: `gbbs_ss_widest_path`; ABI: `i64_array_bytes_output`.
- Input layout: `[node_count, edge_count, source, (from, to, capacity)...]`.
- Bounds: `1 <= node_count <= 16`, `0 <= edge_count <= 64`, and
  `0 <= source < node_count`. Each directed edge endpoint is in
  `[0,node_count)`, and each capacity is in `[1,32]`. Parallel edges and
  self-loops are allowed. Input length must equal `3 + 3*edge_count`.
- Output: one little-endian signed i64 width per vertex, in vertex order.
  The source receives `INT32_MAX` (`2,147,483,647`), as in the GBBS kernel's
  initial width. Unreachable vertices receive zero. Success returns
  `8*node_count`; malformed input returns `-1`; null output or insufficient
  capacity returns `-2` without writing.
- The ports use deterministic single-worker max-priority selection and relax
  an outgoing edge with `candidate = min(width[u], edge_capacity)`, replacing
  the destination width only on a strict increase. This is an exact bounded
  projection of GBBS's monotone ring-bucket traversal. It omits parallel edge
  maps, scheduler behavior, timing, logging, and graph file loading. Positive
  capacities make the source's zero/unvisited sentinel unambiguous.

The package oracle computes an all-pairs max-min closure; the suite verifier
uses repeated edge-sweep relaxation. The workload includes parallel capacities, a bottleneck route that
beats a direct edge, cycles, directed disconnection, maximum-size output, and
malformed/capacity cases.

## Source and rights

Behavior reference: [`SSWidestPath.h::SSWidestPath` and `widestpath::Visit_F`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/SSWidestPath/JulienneDBS17/SSWidestPath.h), pinned to ParAlg/GBBS commit
`dbd1dcad582c0a316c5ba0d5524319d596dd82da`. The benchmark launcher is
[`SSWidestPath.cc`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/SSWidestPath/JulienneDBS17/SSWidestPath.cc).
The repository is MIT licensed; its full upstream license is retained in
[`LICENSE.txt`](LICENSE.txt). All nine ports are clean-room implementations.

## Files

| Language | Source |
| --- | --- |
| C | [`c/w/gbbs_ss_widest_path.c`](../../../c/w/gbbs_ss_widest_path.c) |
| C3 | [`c3/w/gbbs_ss_widest_path.c3`](../../../c3/w/gbbs_ss_widest_path.c3) |
| C++ | [`cpp/w/gbbs_ss_widest_path.cpp`](../../../cpp/w/gbbs_ss_widest_path.cpp) |
| Elisa | [`elisa/w/gbbs_ss_widest_path.elisa`](../../../elisa/w/gbbs_ss_widest_path.elisa) |
| Nim | [`nim/w/gbbs_ss_widest_path.nim`](../../../nim/w/gbbs_ss_widest_path.nim) |
| Odin | [`odin/w/gbbs_ss_widest_path.odin`](../../../odin/w/gbbs_ss_widest_path.odin) |
| Rust | [`rust/w/gbbs_ss_widest_path.rs`](../../../rust/w/gbbs_ss_widest_path.rs) |
| V | [`v/w/gbbs_ss_widest_path.v`](../../../v/w/gbbs_ss_widest_path.v) |
| Zig | [`zig/w/gbbs_ss_widest_path.zig`](../../../zig/w/gbbs_ss_widest_path.zig) |

Workload: [`workload.json`](workload.json). Package oracle:
[`gbbs_ss_widest_path_oracle.py`](../../gbbs_ss_widest_path_oracle.py).
