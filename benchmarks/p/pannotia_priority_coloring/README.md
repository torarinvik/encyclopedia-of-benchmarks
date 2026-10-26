# Pannotia priority-extrema graph coloring

This package captures the Pannotia `coloring_max` and `coloring_maxmin`
variants as two modes of one round-based priority-extrema coloring operation.
Each round examines the currently uncolored graph. Both modes color strict
local maxima with the current color. The `maxmin` mode also colors strict local
minima with the next color. Only colored vertices leave the uncolored set;
other neighbors remain for later rounds. Maxima and minima selected in
one `maxmin` round may be adjacent because they receive different colors.
With distinct priorities, the returned colors are proper on the bounded domain
below.

## Contract

- Exported symbol: `pannotia_priority_coloring`; ABI: `i64_array_bytes_output`.
- Input is `[n, m, mode, p0, ..., p(n-1), (u, v)...]`, with `1 <= n <= 16`
  and `0 <= m <= 64`. Mode `0` is `coloring_max`; mode `1` is
  `coloring_maxmin`. Edges are simple undirected pairs with `u < v`; each
  vertex must have degree other than one. Priorities are unique integers in
  `[0,99,999,998]`.
- The degree-one restriction preserves a source kernel guard: both OpenCL
  kernels skip neighbor comparisons for a CSR row containing exactly one
  entry, which can assign equal colors to adjacent leaves. Isolated vertices
  are supported; in `maxmin`, both extrema predicates hold and the later
  minimum assignment gives the isolated vertex the next color.
- The result contains one positive signed i64 color per vertex in ID order,
  encoded little-endian. Success returns `8*n`; malformed input returns `-1`;
  null or insufficient output capacity returns `-2` without writing.
- Pannotia initializes priorities after `srand(7)` with
  `rand()/(float)RAND_MAX`. The contract supplies the distinct priority order
  explicitly because C-library `rand()` streams vary by runtime. Integer
  ranks preserve the source's strict comparison operations.
- The package oracle calculates round extrema using adjacency rows; the suite
  verifier independently discovers per-vertex extrema and removes only
  vertices assigned a color. It does not reproduce OpenCL scheduling or graph
  file loading.

## Source and rights

The max-only source is [`coloring_max.cpp`](https://github.com/pannotia/pannotia/blob/16c1f0964516babc13a60f21c74644e28f3651b1/graph_app/color/coloring_max.cpp)
with [`kernel_max.cl`](https://github.com/pannotia/pannotia/blob/16c1f0964516babc13a60f21c74644e28f3651b1/graph_app/color/kernel/kernel_max.cl).
The two-color source is [`coloring_maxmin.cpp`](https://github.com/pannotia/pannotia/blob/16c1f0964516babc13a60f21c74644e28f3651b1/graph_app/color/coloring_maxmin.cpp)
with [`kernel_maxmin.cl`](https://github.com/pannotia/pannotia/blob/16c1f0964516babc13a60f21c74644e28f3651b1/graph_app/color/kernel/kernel_maxmin.cl).
Both are pinned to Pannotia commit `16c1f0964516babc13a60f21c74644e28f3651b1`.
The full repository license is in [`LICENSE.txt`](LICENSE.txt); these ports are
clean-room implementations.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/pannotia_priority_coloring.c`](../../../c/p/pannotia_priority_coloring.c) |
| C3 | [`c3/p/pannotia_priority_coloring.c3`](../../../c3/p/pannotia_priority_coloring.c3) |
| C++ | [`cpp/p/pannotia_priority_coloring.cpp`](../../../cpp/p/pannotia_priority_coloring.cpp) |
| Elisa | [`elisa/p/pannotia_priority_coloring.elisa`](../../../elisa/p/pannotia_priority_coloring.elisa) |
| Nim | [`nim/p/pannotia_priority_coloring.nim`](../../../nim/p/pannotia_priority_coloring.nim) |
| Odin | [`odin/p/pannotia_priority_coloring.odin`](../../../odin/p/pannotia_priority_coloring.odin) |
| Rust | [`rust/p/pannotia_priority_coloring.rs`](../../../rust/p/pannotia_priority_coloring.rs) |
| V | [`v/p/pannotia_priority_coloring.v`](../../../v/p/pannotia_priority_coloring.v) |
| Zig | [`zig/p/pannotia_priority_coloring.zig`](../../../zig/p/pannotia_priority_coloring.zig) |

Workload: [`workload.json`](workload.json). Package oracle:
[`pannotia_priority_coloring_oracle.py`](../../pannotia_priority_coloring_oracle.py).
