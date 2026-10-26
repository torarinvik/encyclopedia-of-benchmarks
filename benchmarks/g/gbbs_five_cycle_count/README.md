# GBBS undirected five-cycle count

This package isolates the exact simple five-cycle count from GBBS's
`Parallel5Cycle` benchmark. Each cycle has five distinct vertices and is
counted once regardless of its starting point or traversal direction. This
fixed-length undirected cycle count is distinct from local directed-cycle
enumeration over arbitrary lengths.

## Bounded contract

- Exported symbol: `gbbs_five_cycle_count`; ABI:
  `i64_array_bytes_output`.
- Input: `[node_count, edge_count, (u, v)...]` for a simple undirected graph,
  with every edge supplied once in canonical order `u < v`.
- Bounds: `1 <= node_count <= 16`, `0 <= edge_count <= 64`, exact input
  length `2 + 2*edge_count`. Disconnected and edgeless graphs are valid.
- Operation: exact count of undirected simple cycles of length five. Output is
  one little-endian signed i64 count; success returns eight bytes. Malformed
  input returns `-1`; null output or insufficient capacity returns `-2`
  without writing.
- Projection: the source degree-relabels and orients the graph before its
  Kowalik neighborhood-intersection count. The bounded profile replaces the
  source orientation and parallel scratch-management with direct canonical
  enumeration: root each cycle at its minimum vertex and keep one of its two
  directions. The exact count does not depend on the orientation. Sparsified,
  ESCAPE, and experimental source modes are excluded.

## Source and rights

The source is pinned to
[ParAlg/gbbs commit `dbd1dcad582c0a316c5ba0d5524319d596dd82da`](https://github.com/ParAlg/gbbs/tree/dbd1dcad582c0a316c5ba0d5524319d596dd82da).
The launcher is
[`FiveCycle.cc::Count5Cycle_runner`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/CycleCounting/Parallel5Cycle/FiveCycle.cc);
the source counter is
[`FiveCycle.h::Count5Cycle` and `Count5CycleVertex`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/CycleCounting/Parallel5Cycle/FiveCycle.h).
The repository is MIT licensed. The full notice is retained in
[LICENSE.txt](LICENSE.txt); all ports are clean-room implementations.

## Ports

| Language | Source |
| --- | --- |
| C | [c/g/gbbs_five_cycle_count.c](../../../c/g/gbbs_five_cycle_count.c) |
| C3 | [c3/g/gbbs_five_cycle_count.c3](../../../c3/g/gbbs_five_cycle_count.c3) |
| C++ | [cpp/g/gbbs_five_cycle_count.cpp](../../../cpp/g/gbbs_five_cycle_count.cpp) |
| Elisa | [elisa/g/gbbs_five_cycle_count.elisa](../../../elisa/g/gbbs_five_cycle_count.elisa) |
| Nim | [nim/g/gbbs_five_cycle_count.nim](../../../nim/g/gbbs_five_cycle_count.nim) |
| Odin | [odin/g/gbbs_five_cycle_count.odin](../../../odin/g/gbbs_five_cycle_count.odin) |
| Rust | [rust/g/gbbs_five_cycle_count.rs](../../../rust/g/gbbs_five_cycle_count.rs) |
| V | [v/g/gbbs_five_cycle_count.v](../../../v/g/gbbs_five_cycle_count.v) |
| Zig | [zig/g/gbbs_five_cycle_count.zig](../../../zig/g/gbbs_five_cycle_count.zig) |

Fixtures are in [workload.json](workload.json). The package oracle enumerates
combinations and canonical permutations; the independent verifier scans
canonical paths directly from the edge set.
