# SPLASH-2 Water-Spatial (bounded projection)

This package benchmarks a uniform-cell spatial search for a bounded molecular
pair-interaction workload. It is a clean-room algorithmic projection inspired
by SPLASH-2 Water-Spatial, not a reproduction of its complete water force
field, rigid-water model, predictor-corrector integrator, parallel runtime, or
input format.

## Operation

Input is `[N, G, R, (x, y, z, q)*]`: `N` is 0..64 molecules, `G` is the side
length of a cubic grid (1..8), `R` is an integer cutoff (1..4), each integer
coordinate is in `[0, G*R)`, and each charge `q` is in -4..4. The box is
nonperiodic. Cells have side length `R`, so each molecule belongs to one of
`G^3` cells. For each molecule, the port visits its own and the 26 adjacent
cells, clipping cell coordinates at the box boundary. It considers only
unordered molecule pairs once.

For displacement `d = (x_j-x_i, y_j-y_i, z_j-z_i)` and `r² = d·d`, a pair
contributes only when `r² < R²`. Its shifted softened potential and force on
`i` are

```text
U_ij = q_i q_j (R²-r²) / ((1+r²)(1+R²))
F_i  = -2 q_i q_j d / (1+r²)²
```

Each pair contribution is multiplied by 1,000,000 and divided with signed
integer truncation toward zero before accumulation. The opposite force is
added to molecule `j`. The byte output is `[Fx,Fy,Fz]` for every molecule in
input order, followed by total scaled pair potential and accepted-pair count,
as little-endian signed 64-bit integers. The maximum output is 1,552 bytes;
the bounded grid/list/force storage is 6,160 bytes. Invalid input returns
`-1`; valid input with null or short output returns `-2` without writes.

## Algorithm distinction and complexity

The paired [Water-Nsquared profile](../../s/splash2_water_nsquared/README.md)
evaluates all molecule pairs. This profile uses linked cell lists and checks
only nearby cells before applying the same cutoff pair law.
It therefore measures spatial binning and neighbor traversal, not an all-pairs
loop. Setup is `O(N+G^3)`; pair work is proportional to the candidate pairs in
the 27-cell neighborhoods, with worst case `O(N²)` when particles are crowded
into a few cells. The bounded direct oracle ignores the grid and enumerates
all `i<j` pairs, so it provides an algorithmically independent reference.

The local Rodinia LavaMD profile takes particles already grouped into a home
box and one supplied neighbor box, then applies its screened exponential
interaction. It does not construct cell buckets or discover neighboring cells
from coordinates. The local N-body profile is a two-dimensional softened
gravity update with an Euler integration step, so it has a different force law
and state transition as well.

The [SPLASH-2 characterization paper](https://pages.cs.wisc.edu/~markhill/restricted/isca95_splash2.pdf)
describes Water-Spatial as imposing a uniform 3-D cell grid and searching
neighboring cells for molecules within a cutoff. The [SPLASH-2 source mirror](https://github.com/staceyson/splash2)
contains the original suite documentation. See [workload.json](workload.json),
the [direct all-pairs oracle](../../water_spatial_oracle.py), the
[independent target-wise oracle](../../water_spatial_verifier_oracle.py), and
[RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Port |
|---|---|
| C | [`c/w/water_spatial.c`](../../../c/w/water_spatial.c) |
| C3 | [`c3/w/water_spatial.c3`](../../../c3/w/water_spatial.c3) |
| C++ | [`cpp/w/water_spatial.cpp`](../../../cpp/w/water_spatial.cpp) |
| Elisa | [`elisa/w/water_spatial.elisa`](../../../elisa/w/water_spatial.elisa) |
| Mojo | [`mojo/w/water_spatial.mojo`](../../../mojo/w/water_spatial.mojo) |
| Nim | [`nim/w/water_spatial.nim`](../../../nim/w/water_spatial.nim) |
| Odin | [`odin/w/water_spatial.odin`](../../../odin/w/water_spatial.odin) |
| Rust | [`rust/w/water_spatial.rs`](../../../rust/w/water_spatial.rs) |
| V | [`v/w/water_spatial.v`](../../../v/w/water_spatial.v) |
| Zig | [`zig/w/water_spatial.zig`](../../../zig/w/water_spatial.zig) |
