# GBBS fixed four-clique count

This package isolates the exact `k=4` count from GBBS's k-clique benchmark.
It uses the source-supported `ORIGINAL` ordering: every undirected edge is
oriented from its smaller vertex ID to its larger ID, the source's `k-1`
degree filter removes vertices that cannot occur in a four-clique, and the
counter intersects successive outgoing neighborhoods. Each four-vertex clique
is counted once. This is distinct from local triangle counters, which count
the `k=3` case.

## Bounded contract

- Exported symbol: `gbbs_k_clique_count`; ABI: `i64_array_bytes_output`.
- Input: `[node_count, edge_count, (u, v)...]`, a simple undirected graph
  encoded once per edge with `u < v`.
- Bounds: `1 <= node_count <= 24`, `0 <= edge_count <= 64`, exact input
  length `2 + 2*edge_count`. Graphs can be disconnected or edgeless.
- Operation: exact four-clique count with `-k 4 --directType ORIGINAL` source
  settings. Output is one little-endian signed i64 count and success returns
  eight bytes. Malformed input returns `-1`; null output or capacity below
  eight returns `-2` without writing.
- Projection: the ports replace parallel scheduling and recursive scratch
  storage with bounded nested neighborhood intersections. They exclude
  per-vertex counts, vertex peeling, approximate counting, sparsification, and
  the other source ordering modes.

## Source and rights

The source is pinned to
[ParAlg/gbbs commit `dbd1dcad582c0a316c5ba0d5524319d596dd82da`](https://github.com/ParAlg/gbbs/tree/dbd1dcad582c0a316c5ba0d5524319d596dd82da).
The launcher is `benchmarks/CliqueCounting/Clique.cc::AppKCore_runner`; the
count path is `benchmarks/CliqueCounting/Clique.h::Clique` and
`induced_intersection::CountCliques` in
[`induced_intersection.h`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/CliqueCounting/induced_intersection.h).
The profile selects the supported `--directType ORIGINAL` option and fixed
`-k 4`; it does not claim the launcher's default ordering. GBBS is MIT
licensed. The full notice is retained in [LICENSE.txt](LICENSE.txt); all
ports are clean-room implementations.

## Ports

| Language | Source |
| --- | --- |
| C | [c/g/gbbs_k_clique_count.c](../../../c/g/gbbs_k_clique_count.c) |
| C3 | [c3/g/gbbs_k_clique_count.c3](../../../c3/g/gbbs_k_clique_count.c3) |
| C++ | [cpp/g/gbbs_k_clique_count.cpp](../../../cpp/g/gbbs_k_clique_count.cpp) |
| Elisa | [elisa/g/gbbs_k_clique_count.elisa](../../../elisa/g/gbbs_k_clique_count.elisa) |
| Nim | [nim/g/gbbs_k_clique_count.nim](../../../nim/g/gbbs_k_clique_count.nim) |
| Odin | [odin/g/gbbs_k_clique_count.odin](../../../odin/g/gbbs_k_clique_count.odin) |
| Rust | [rust/g/gbbs_k_clique_count.rs](../../../rust/g/gbbs_k_clique_count.rs) |
| V | [v/g/gbbs_k_clique_count.v](../../../v/g/gbbs_k_clique_count.v) |
| Zig | [zig/g/gbbs_k_clique_count.zig](../../../zig/g/gbbs_k_clique_count.zig) |

Workload fixtures are in [workload.json](workload.json). The package oracle
uses intersections of oriented neighbor sets; the independent verifier
enumerates unordered four-vertex combinations against a dense adjacency
matrix.
