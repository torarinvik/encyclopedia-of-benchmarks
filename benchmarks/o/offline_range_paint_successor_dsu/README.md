# Offline range painting with a successor DSU

The input contains a chronological list of inclusive interval color
assignments. The primary processes assignments in reverse order. Each cell is
written the first time it is reached; a successor DSU then jumps over it on
later reverse steps. This directly implements the “next unpainted cell”
invariant.

## Contract

The `i64_array_scalar` input is `[n,q,(left,right,color)*q]`, with
`1<=n<=64`, `0<=q<=64`, inclusive zero-based bounds `0<=left<=right<n`, and
colors in `[-1000,1000]`. Later assignments overwrite earlier assignments.
Cells begin with color zero. The result is
`sum((index+1)*(final_color+1001))`; malformed input returns `-1`.

The primary processes each cell at most once while using path-compressed
successor links, for `O((n+q) alpha(n))` bounded work. The independent oracle
applies every assignment forward to a flat array.

This differs from [`range_union_find`](../../r/range_union_find/README.md),
which merges adjacent vertices and skips component boundaries, and from
dynamic lazy range-assignment trees, which handle online updates. Here the
operation order is known and reverse processing skips cells whose final value
is fixed.

## Provenance and inventory

The idea comes from CP-Algorithms' [Disjoint Set Union article, “Compress
jumps along a segment / Painting subarrays offline”](https://cp-algorithms.com/data_structures/disjoint_set_union.html),
published under CC BY-SA 4.0. The contract, code, references, fixtures, and
prose are independently authored. See [RIGHTS.md](RIGHTS.md). The workload
covers overlaps, full and disjoint ranges, an empty update list, and the
maximum frame. That frame contains 64 repeated assignments painting only
cell 0 to color 1; the checksum is 2,082,081. [`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py) use successor skipping and
forward array writes respectively; [`verify_workload.py`](verify_workload.py)
is a source-only inventory checker.

| Language | Source |
|---|---|
| C | [`c/o/offline_range_paint_successor_dsu.c`](../../../c/o/offline_range_paint_successor_dsu.c) |
| C3 | [`c3/o/offline_range_paint_successor_dsu.c3`](../../../c3/o/offline_range_paint_successor_dsu.c3) |
| C++ | [`cpp/o/offline_range_paint_successor_dsu.cpp`](../../../cpp/o/offline_range_paint_successor_dsu.cpp) |
| Elisa | [`elisa/o/offline_range_paint_successor_dsu.elisa`](../../../elisa/o/offline_range_paint_successor_dsu.elisa) |
| Mojo | [`mojo/o/offline_range_paint_successor_dsu.mojo`](../../../mojo/o/offline_range_paint_successor_dsu.mojo) |
| Nim | [`nim/o/offline_range_paint_successor_dsu.nim`](../../../nim/o/offline_range_paint_successor_dsu.nim) |
| Odin | [`odin/o/offline_range_paint_successor_dsu.odin`](../../../odin/o/offline_range_paint_successor_dsu.odin) |
| Rust | [`rust/o/offline_range_paint_successor_dsu.rs`](../../../rust/o/offline_range_paint_successor_dsu.rs) |
| V | [`v/o/offline_range_paint_successor_dsu.v`](../../../v/o/offline_range_paint_successor_dsu.v) |
| Zig | [`zig/o/offline_range_paint_successor_dsu.zig`](../../../zig/o/offline_range_paint_successor_dsu.zig) |
