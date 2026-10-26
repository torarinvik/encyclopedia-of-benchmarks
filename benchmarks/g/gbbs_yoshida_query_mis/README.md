# GBBS Yoshida recursive MIS query

This package isolates one `mis_query` call from GBBS's Yoshida maximal
independent-set implementation. It explores neighbors in ascending
`hash64(vertex)` priority order, recursively checks only lower-priority
neighbors, and stops early when an in-set neighbor is found. A finite query
cutoff returns the source's `unknown` status when the work budget is reached.
This differs from Pannotia's simultaneous local-minimum-priority rounds.

## Contract

- Exported symbol: `gbbs_yoshida_query_mis`; ABI: `i64_array_bytes_output`.
- Input: `[node_count, edge_count, query_vertex, query_cutoff, (u, v)...]`.
- Bounds: `1 <= node_count <= 12`, `0 <= edge_count <= 24`, and
  `0 <= query_cutoff <= 128`; exact input length is `4 + 2*edge_count`.
- The graph is simple and undirected. Each edge occurs once with `u < v`.
- The query derives each vertex priority from the pinned ParlayLib `hash64`
  function and orders equal priorities by vertex ID, as `reorder_graph` does.
- Output is two little-endian signed 64-bit values: status (`1` for in the
  queried independent set, `0` for out, `-1` for unknown) and the number of
  neighbor visits made. Success returns 16 bytes. Invalid input returns `-1`;
  null output or insufficient capacity returns `-2` without writing.
- The cutoff is the recursive query's cumulative neighbor-visit budget, reset
  to zero for this root query. An isolated vertex returns in with zero work,
  including at cutoff zero.

The bounded ABI exposes one source query and its work count. The launcher runs
one query for every vertex and aggregates maximum work, total work, and
fraction covered; those whole-graph timing/statistics are outside this
single-query profile.

## Source and rights

The behavior is pinned to GBBS commit
[`dbd1dcad582c0a316c5ba0d5524319d596dd82da`](https://github.com/ParAlg/gbbs/tree/dbd1dcad582c0a316c5ba0d5524319d596dd82da):
[`MaximalIndependentSet.h::mis_query`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/MaximalIndependentSet/Yoshida/MaximalIndependentSet.h#L513-L593),
[`reorder.h::reorder_graph`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/MaximalIndependentSet/Yoshida/reorder.h#L320-L410),
and [`MaximalIndependentSet.cc::MaximalIndependentSet_runner`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/MaximalIndependentSet/Yoshida/MaximalIndependentSet.cc#L456-L501).
The launcher requires symmetric graph input and defaults `-query_cutoff` to
`SIZE_MAX`. Its source defines priorities with ParlayLib `hash64`; GBBS pins
ParlayLib commit
[`352f5367a6b3bd2f0c6f05882cdd02e978e349ea`](https://github.com/ParAlg/parlaylib/tree/352f5367a6b3bd2f0c6f05882cdd02e978e349ea),
where the transform is in
[`include/parlay/utilities.h`](https://github.com/ParAlg/parlaylib/blob/352f5367a6b3bd2f0c6f05882cdd02e978e349ea/include/parlay/utilities.h#L176-L185).
GBBS and ParlayLib are MIT licensed; both complete notices are retained in
[`LICENSE.txt`](LICENSE.txt). The nine language ports are clean-room
implementations of the query semantics.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/g/gbbs_yoshida_query_mis.c`](../../../c/g/gbbs_yoshida_query_mis.c) |
| C3 | [`c3/g/gbbs_yoshida_query_mis.c3`](../../../c3/g/gbbs_yoshida_query_mis.c3) |
| C++ | [`cpp/g/gbbs_yoshida_query_mis.cpp`](../../../cpp/g/gbbs_yoshida_query_mis.cpp) |
| Elisa | [`elisa/g/gbbs_yoshida_query_mis.elisa`](../../../elisa/g/gbbs_yoshida_query_mis.elisa) |
| Nim | [`nim/g/gbbs_yoshida_query_mis.nim`](../../../nim/g/gbbs_yoshida_query_mis.nim) |
| Odin | [`odin/g/gbbs_yoshida_query_mis.odin`](../../../odin/g/gbbs_yoshida_query_mis.odin) |
| Rust | [`rust/g/gbbs_yoshida_query_mis.rs`](../../../rust/g/gbbs_yoshida_query_mis.rs) |
| V | [`v/g/gbbs_yoshida_query_mis.v`](../../../v/g/gbbs_yoshida_query_mis.v) |
| Zig | [`zig/g/gbbs_yoshida_query_mis.zig`](../../../zig/g/gbbs_yoshida_query_mis.zig) |

Fixtures are listed in [`workload.json`](workload.json). The package oracle
uses the recursive source recurrence; the verifier oracle simulates it with
an explicit frame stack.
