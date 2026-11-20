# Bricks falling after grid hits, reversed with DSU

This bounded profile processes a known sequence of distinct cell hits in
reverse. A disjoint-set structure connects the current brick cells and a
virtual roof. Restoring one cell can join previously unsupported components;
the change in roof-component size, excluding the restored cell itself, gives
the number of other bricks that fall after the corresponding forward hit.

## Contract

Input is `[rows,columns,hit_count,grid_cells...,hit_coordinates...]` using
signed 64-bit words. The grid is row-major with `1` for a brick and `0` for an
empty cell. Dimensions are each `1..8`, hit count is `0..16`, and all initial
bricks must be connected by four-neighbor steps to some occupied top-row
cell. The final `2*hit_count` words are `(row,column)` pairs in forward order.
Coordinates must be in bounds and distinct. Hits on cells that are empty at
that moment are valid and produce zero drops, including cells that became
unsupported after an earlier hit. A hit on a present brick removes that cell;
every other cell no longer connected to the top is removed immediately.
Repeated hit coordinates and initially unstable grids are malformed.

Output is one nonnegative signed-i64 drop count per hit, in forward order,
encoded as little-endian words. The return value is `8*hit_count`. A zero-hit
trace returns zero bytes and permits a null output. Malformed input returns
`-1`; null output or insufficient capacity for a nonempty result returns
`-2`. Validation precedes output-capacity checks, and errors write nothing.
Maximum valid and parseable input lengths are 99 and 100 words; output is
bounded at 128 bytes. Native scratch is 584 bytes: a 64-byte mutable grid and
two 65-element i32 arrays for DSU parents and component sizes. The extra DSU
element is the virtual roof; caller-owned input/output are excluded.

## Algorithm and distinction

The primary port validates the initial roof-connected invariant, removes all
specified brick hits, builds DSU components for the remaining cells, then
restores hits from last to first. For each restored brick it records the roof
component size before and after joining adjacent restored/remaining bricks.
The difference minus the newly restored cell, floored at zero, is stored at
that hit's original output position. The independent reference simulates
forward: it removes each hit, floods from the top row, and deletes every cell
that becomes unreachable.

[`max_area_of_island`](../../m/max_area_of_island/README.md) and
[`number_of_islands`](../../n/number_of_islands/README.md) count static grid
components. [`offline_dynamic_connectivity`](../../o/offline_dynamic_connectivity/README.md)
and [`dynamic_graph_vertex_add_component_sum`](../../d/dynamic_graph_vertex_add_component_sum/README.md)
use a segment tree over event time with rollback DSU. This profile uses a
one-way reverse restoration pass and measures roof-connected component-size
growth for a gravity-style deletion trace.

## Sources and rights

The public [LeetCode 803 title](https://leetcode.com/problems/bricks-falling-when-hit/)
was used only as an idea index. The general offline reversal and DSU component
size methods are described in CP-Algorithms'
[DSU article](https://cp-algorithms.com/data_structures/disjoint_set_union.html).
This package's bounded contract, workload, references, ports, and prose are
original. No task statement, code, constraints, examples, tests, or submissions
are copied.

[`workload.json`](workload.json) uses repository-created grids and hit traces.
[`verify_workload.py`](verify_workload.py) compares the two references and
checks pinned outputs; [`check_inventory.py`](check_inventory.py) is a static
source inventory helper. Neither helper was run.

## Native ports

| Language | Source |
| --- | --- |
| C | [`c/b/bricks_falling_when_hit_reverse_dsu.c`](../../../c/b/bricks_falling_when_hit_reverse_dsu.c) |
| C3 | [`c3/b/bricks_falling_when_hit_reverse_dsu.c3`](../../../c3/b/bricks_falling_when_hit_reverse_dsu.c3) |
| C++ | [`cpp/b/bricks_falling_when_hit_reverse_dsu.cpp`](../../../cpp/b/bricks_falling_when_hit_reverse_dsu.cpp) |
| Elisa | [`elisa/b/bricks_falling_when_hit_reverse_dsu.elisa`](../../../elisa/b/bricks_falling_when_hit_reverse_dsu.elisa) |
| Mojo | [`mojo/b/bricks_falling_when_hit_reverse_dsu.mojo`](../../../mojo/b/bricks_falling_when_hit_reverse_dsu.mojo) |
| Nim | [`nim/b/bricks_falling_when_hit_reverse_dsu.nim`](../../../nim/b/bricks_falling_when_hit_reverse_dsu.nim) |
| Odin | [`odin/b/bricks_falling_when_hit_reverse_dsu.odin`](../../../odin/b/bricks_falling_when_hit_reverse_dsu.odin) |
| Rust | [`rust/b/bricks_falling_when_hit_reverse_dsu.rs`](../../../rust/b/bricks_falling_when_hit_reverse_dsu.rs) |
| V | [`v/b/bricks_falling_when_hit_reverse_dsu.v`](../../../v/b/bricks_falling_when_hit_reverse_dsu.v) |
| Zig | [`zig/b/bricks_falling_when_hit_reverse_dsu.zig`](../../../zig/b/bricks_falling_when_hit_reverse_dsu.zig) |
