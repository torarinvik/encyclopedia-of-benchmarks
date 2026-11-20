# Connectivity-aware plug DP for binary grid colorings

Count the labeled black/white colorings of a fully available rectangular grid
with `2<=rows,columns<=4` such that both color classes are nonempty and
4-neighbor connected, and no 2x2 block is monochromatic. The returned count is
exact and at most `2^16`.

The primary reference scans cells row by row. Its frontier stores canonical
component labels for each color. Adding a cell joins its matching left and
upper components, rejects a monochromatic 2x2 block, and canonicalizes labels.
If a component disappears while another component of the same color remains,
the state is rejected. If the unique component of a color disappears, that
color is marked complete and cannot be selected again. This completed-color
state is needed because one connected color class can finish before the final
grid cell. At the end, each color must be either complete or represented by
exactly one frontier component.

The independent reference enumerates every full assignment, flood-fills each
color class, and checks every 2x2 square directly. The profile borrows the
connectivity-aware frontier method described in OI Wiki's
[Plug DP article](https://en.oi-wiki.org/dp/plug/); the UVA 10572 “Black &
White” problem is a discovery/model reference. This small, fully occupied
rectangle contract is repository-defined. No article text, task text, or code
is copied. See [RIGHTS.md](RIGHTS.md) and [workload.json](workload.json).

This package counts connectivity-constrained colorings. It differs from
occupancy-only domino tiling profiles, generic proper graph-coloring counts,
and algorithms that construct one coloring without enforcing connected color
classes.

| Language | Source |
|---|---|
| C | [`c/c/connectivity_aware_plug_dp_binary_grid_colorings.c`](../../../c/c/connectivity_aware_plug_dp_binary_grid_colorings.c) |
| C3 | [`c3/c/connectivity_aware_plug_dp_binary_grid_colorings.c3`](../../../c3/c/connectivity_aware_plug_dp_binary_grid_colorings.c3) |
| C++ | [`cpp/c/connectivity_aware_plug_dp_binary_grid_colorings.cpp`](../../../cpp/c/connectivity_aware_plug_dp_binary_grid_colorings.cpp) |
| Elisa | [`elisa/c/connectivity_aware_plug_dp_binary_grid_colorings.elisa`](../../../elisa/c/connectivity_aware_plug_dp_binary_grid_colorings.elisa) |
| Mojo | [`mojo/c/connectivity_aware_plug_dp_binary_grid_colorings.mojo`](../../../mojo/c/connectivity_aware_plug_dp_binary_grid_colorings.mojo) |
| Nim | [`nim/c/connectivity_aware_plug_dp_binary_grid_colorings.nim`](../../../nim/c/connectivity_aware_plug_dp_binary_grid_colorings.nim) |
| Odin | [`odin/c/connectivity_aware_plug_dp_binary_grid_colorings.odin`](../../../odin/c/connectivity_aware_plug_dp_binary_grid_colorings.odin) |
| Rust | [`rust/c/connectivity_aware_plug_dp_binary_grid_colorings.rs`](../../../rust/c/connectivity_aware_plug_dp_binary_grid_colorings.rs) |
| V | [`v/c/connectivity_aware_plug_dp_binary_grid_colorings.v`](../../../v/c/connectivity_aware_plug_dp_binary_grid_colorings.v) |
| Zig | [`zig/c/connectivity_aware_plug_dp_binary_grid_colorings.zig`](../../../zig/c/connectivity_aware_plug_dp_binary_grid_colorings.zig) |

The package-local [static inventory checker](check_inventory.py) cross-checks
the pinned workload, both references, and all ten port paths. It has not been
run.
