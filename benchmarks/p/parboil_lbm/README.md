# Parboil LBM: bounded D3Q19 stream and collide

`parboil_lbm` implements one source-ordered lattice-Boltzmann stream/collide
step on a 3×3×3 D3Q19 grid. It keeps the only fluid cell at the center and
uses the pinned LDC (lid-driven cavity) face rule: every cell on any grid face
is an obstacle. The center runs the single-relaxation-time collision; the
face cells perform the source's opposite-population bounce-back stores. This
is a compact profile of Parboil's LBM kernel, not the repository's full
120×120×150 timed workload.

## Contract

- Exported scalar symbol: `parboil_lbm`; ABI: `i64_array_scalar`.
- Input is exactly 19 signed-i64 values in D3Q19 order:
  `C,N,S,E,W,T,B,NE,NW,SE,SW,NT,NB,ST,SB,ET,EB,WT,WB`.
- Each slot is a nonnegative population in `[0,100000]`, encoded in units of
  `1e-6`. The center cell receives the encoded values; every other source cell
  starts at Parboil's D3Q19 equilibrium weights. The all-zero center vector is
  invalid because its density is zero.
- The direction vectors are the source's D3Q19 stencil. Cells are visited in
  z, y, x order with x fastest. Fluid populations collide and stream to the
  adjacent destination in their direction. Obstacle populations stream their
  opposite source population to the adjacent destination in the source's
  direction. This preserves the pinned `COLLIDE_STREAM` boundary branch.
- The profile runs one time step. Source acceleration and channel in/out-flow
  handling do not apply to this 3×3×3 LDC case.
- The observable is the weighted fixed-point checksum
  `sum((cell_index+1) * round_away(population*1e6))` over all 27 active
  destination cells and 19 populations per cell. `cell_index=x+3*y+9*z`;
  `round_away` rounds half values away from zero. Results are signed i64.
- Source `DFL1`, `DFL2`, and `DFL3` are unsuffixed double constants. The
  profile rounds the density, velocity, polynomial factors, and base term to
  binary32 in source order, computes the equilibrium product in binary64, adds
  the binary32 base in binary64, then stores the result as binary32. Population
  quantization also occurs after binary32 multiplication by `1e6`.
- The pinned C code does not specify compiler floating-point flags. This
  profile assumes IEEE round-to-nearest binary32 at the stated float
  operations, binary64 for the double-macro products, and no reassociation or
  contraction; different historical compiler settings may change low bits.
- Null input, a length other than 19, out-of-range populations, or zero total
  density returns `-1`.

The static rest-only fixture uses center `C=0.1`, zero for its other 18
populations, and equilibrium initialization elsewhere. Its collision produces
quantized center outputs `C=-30000`, axial `10833`, and diagonal `5417`; the
equilibrium baseline is `1,000,005 × sum(1..27) = 378,001,890`. The rest
population changes the center contribution by `-363,333 × 14`; the axial
streams replace equilibrium values over destination-cell weights summing to
84, and diagonal streams over weights summing to 168. Applying those changes
gives the fixture checksum `365,401,848`.

The independent Python oracle uses a pull/gather formulation for each output
population rather than reproducing the ports' source-cell push traversal.
It rounds each source float operation explicitly to binary32.

## Source and rights

Pinned source: [`yuhc/gpu-parboil` commit
`ccf3d3126f1754ca85528722f4ced5894ccb852b`](https://github.com/yuhc/gpu-parboil/tree/ccf3d3126f1754ca85528722f4ced5894ccb852b).
The recurrence is in [`lbm.c`](https://github.com/yuhc/gpu-parboil/blob/ccf3d3126f1754ca85528722f4ced5894ccb852b/benchmarks/lbm/src/cpu/lbm.c)
(`LBM_initializeGrid`, `LBM_initializeSpecialCellsForLDC`, and
`LBM_performStreamCollide`); direction and `COLLIDE_STREAM` mappings are in
[`lbm_1d_array.h`](https://github.com/yuhc/gpu-parboil/blob/ccf3d3126f1754ca85528722f4ced5894ccb852b/benchmarks/lbm/src/cpu/lbm_1d_array.h),
and the `OMEGA` constant is in
[`config.h`](https://github.com/yuhc/gpu-parboil/blob/ccf3d3126f1754ca85528722f4ced5894ccb852b/benchmarks/lbm/src/cpu/config.h).
The launcher calls this path from [`main.c`](https://github.com/yuhc/gpu-parboil/blob/ccf3d3126f1754ca85528722f4ced5894ccb852b/benchmarks/lbm/src/cpu/main.c).

The pinned repository includes the Illinois Open Source License. Its full
text is reproduced in [`LICENSE.txt`](LICENSE.txt). The ports are clean-room
implementations of the documented recurrence and do not copy upstream source
text. The main profile limitation is its reduced geometry: it preserves the
single fluid-cell collision, D3Q19 stencil, one-step streaming, and LDC
bounce-back path while omitting full-grid initialization, simulation loops,
input files, and timing wrappers.

Independent oracle: [`benchmarks/parboil_lbm_oracle.py`](../../parboil_lbm_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`parboil_lbm.c`](../../../c/p/parboil_lbm.c) |
| C3 | [`parboil_lbm.c3`](../../../c3/p/parboil_lbm.c3) |
| C++ | [`parboil_lbm.cpp`](../../../cpp/p/parboil_lbm.cpp) |
| Elisa | [`parboil_lbm.elisa`](../../../elisa/p/parboil_lbm.elisa) |
| Nim | [`parboil_lbm.nim`](../../../nim/p/parboil_lbm.nim) |
| Odin | [`parboil_lbm.odin`](../../../odin/p/parboil_lbm.odin) |
| Rust | [`parboil_lbm.rs`](../../../rust/p/parboil_lbm.rs) |
| V | [`parboil_lbm.v`](../../../v/p/parboil_lbm.v) |
| Zig | [`parboil_lbm.zig`](../../../zig/p/parboil_lbm.zig) |
