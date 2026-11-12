# NAS UA mesh adaptation

This package isolates one bounded mesh re-adaptation step from NASA's
[Unstructured Adaptive NAS Parallel Benchmark report NAS-04-006](https://www.nas.nasa.gov/assets/nas/pdf/techreports/2004/nas-04-006.pdf),
§§4.1–4.3. It represents the cubic domain as leaves of an isotropic octree.
Cells intersecting the spherical heat source refine to the class depth; other
cells coarsen in complete groups of eight when the merge preserves the local
level constraint. Refinement propagates to face or edge neighbors as needed
for a one-level difference.

## Contract

ABI: `i64_array_float64`; symbol: `npb_ua_mesh_adaptation`.

The domain is `[0,4]^3` with maximum refinement depth 2. Input is
`[source_x, source_y, source_z, radius, leaf_count, (level,x,y,z)...]`.
Coordinates and radius use integer domain units. The source center is in
`[0,4]^3`, and its radius is in `[1,4]`. Each leaf is an axis-aligned cube;
level `l` gives side length `2^(2-l)`, and lower coordinates must align to
that length. The leaves must cover the domain exactly without overlap and
begin with no face- or edge-neighbor level gap larger than one. There are at
most 64 leaves, so valid input is at most 261 integers. Invalid input returns
`-1e300`.

The heat-source overlap rule uses the squared distance from the source center
to the closest point of a cell and a strict comparison with `radius^2`. The
adaptation refines overlapping cells recursively to depth 2, balances the
mesh, then repeatedly merges complete non-overlapping sibling groups when
the replacement remains balanced. The returned scalar checksum sorts leaves
by `(level,z,y,x)` and computes
`sum((i+1)*(1000*level + 100*x + 10*y + z))`, with zero-based `i`. Compare
the binary64 result with zero tolerance. This projection lets the package
retain the suite's scalar ABI while reflecting both the final leaf set and its
ordering.

This bounded profile measures mesh adaptation only. It does not implement the
spectral-element heat equation, mortar gather/scatter, solution transfer, PCG,
or NPB classes. Local `delaunay_mesh_refinement` inserts one circumcenter in a
2-D triangular mesh, `splash2_radiosity_refine` subdivides square radiosity
patches, `doe_miniamr_stencil_average` updates values on a fixed 3-D block,
and `doe_minigmg_restriction` averages a regular fine grid. None represents
3-D adaptive hexahedral refine/coarsen under a neighbor-level constraint.

The primary explicit-leaf oracle is
[`../../npb_ua_mesh_adaptation_oracle.py`](../../npb_ua_mesh_adaptation_oracle.py).
The independent set-based verifier is
[`../../npb_ua_mesh_adaptation_verifier_oracle.py`](../../npb_ua_mesh_adaptation_verifier_oracle.py).
[`workload.json`](workload.json) contains a root-to-corner refinement case and
a source-movement case that coarsens the old corner while refining the new
one. [`verify_workload.py`](verify_workload.py) checks package paths and
metadata statically.

## Rights

The algorithmic reference is NASA Ames Research Center Technical Report
NAS-04-006. The ports are clean-room implementations of the adaptation rules
described in §§4.1–4.3. No upstream code, comments, figures, or report prose
are reproduced. See [`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/n/npb_ua_mesh_adaptation.c`](../../../c/n/npb_ua_mesh_adaptation.c) |
| C3 | [`c3/n/npb_ua_mesh_adaptation.c3`](../../../c3/n/npb_ua_mesh_adaptation.c3) |
| C++ | [`cpp/n/npb_ua_mesh_adaptation.cpp`](../../../cpp/n/npb_ua_mesh_adaptation.cpp) |
| Elisa | [`elisa/n/npb_ua_mesh_adaptation.elisa`](../../../elisa/n/npb_ua_mesh_adaptation.elisa) |
| Mojo | [`mojo/n/npb_ua_mesh_adaptation.mojo`](../../../mojo/n/npb_ua_mesh_adaptation.mojo) |
| Nim | [`nim/n/npb_ua_mesh_adaptation.nim`](../../../nim/n/npb_ua_mesh_adaptation.nim) |
| Odin | [`odin/n/npb_ua_mesh_adaptation.odin`](../../../odin/n/npb_ua_mesh_adaptation.odin) |
| Rust | [`rust/n/npb_ua_mesh_adaptation.rs`](../../../rust/n/npb_ua_mesh_adaptation.rs) |
| V | [`v/n/npb_ua_mesh_adaptation.v`](../../../v/n/npb_ua_mesh_adaptation.v) |
| Zig | [`zig/n/npb_ua_mesh_adaptation.zig`](../../../zig/n/npb_ua_mesh_adaptation.zig) |
