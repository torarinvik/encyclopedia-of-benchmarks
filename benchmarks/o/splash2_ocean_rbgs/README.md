# SPLASH-2 Ocean red-black relaxation sweep

This package extracts the scalar numerical kernel `relax` from SPLASH-2 Ocean's multigrid solver. The upstream source describes Ocean's solver as red-black Gauss-Seidel relaxation inside multigrid W-cycles, with half-injection residual transfer. This bounded contract runs one red phase followed by one black phase on a square grid with a one-cell boundary. It omits the W-cycle controller, coarse-grid transfer, partitioning, synchronization, and ocean-model setup.

The update factor is `4 - eigenvalue_squared * spacing²`. For interior cell `(row,column)`, the source's red or black relaxation computes `(north + south + west + east - rhs) / factor`; red cells satisfy `(row + column) mod 2 == 0` and are all updated before black cells. It returns the largest absolute cell change from either phase, followed by the complete final grid. Boundary values remain unchanged.

## Contract

ABI `float64_slice_io`, symbol `splash2_ocean_rbgs`. Input is `[side,eigenvalue_squared,spacing,grid...,rhs...]`; the two grids are row-major, each with `side²` values. Supported sides are 4, 6, and 8. Grid and right-hand-side values are finite and in `[-8,8]`; `eigenvalue_squared` is in `[0,2]`; spacing is in `[0.125,1]`. The update factor is therefore positive. Exact input length is `3 + 2*side²` (maximum 131 values). Output is `[maximum_absolute_update,final_grid...]` with `1+side²` values (maximum 65). Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writes. Compare binary64 outputs with absolute and relative tolerances of `1e-12`.

## Duplicate audit

The local [`scimark2_sor`](../../s/scimark2_sor/README.md) applies weighted `omega=1.25` SOR in ascending row-major order and returns a scalar checksum. [`gauss_seidel_method`](../../g/gauss_seidel_method/README.md) solves a generic linear system with sequential coordinate sweeps; the Jacobi packages use simultaneous two-buffer updates. [`doe_minigmg_restriction`](../../d/doe_minigmg_restriction/README.md) is a 3-D cell-centered eight-value average. None uses Ocean's two-color red-then-black smoother and its screened-Poisson update equation. This package benchmarks that distinct numerical kernel, not a second complete application solver.

The primary reference is the pinned SPLASH-2 [`multi.C`](https://github.com/staceyson/splash2/blob/be64f8e4840fc29ff4c076c3f747e27fdb55ac68/codes/apps/ocean/contiguous_partitions/multi.C), especially its `relax` routine and file header. The suite-level algorithm description is in Woo et al., [“The SPLASH-2 Programs: Characterization and Methodological Considerations”](https://doi.org/10.1145/223982.223990). The direct oracle is [`benchmarks/splash2_ocean_rbgs_oracle.py`](../../splash2_ocean_rbgs_oracle.py); a separate nested-matrix checker oracle is [`benchmarks/splash2_ocean_rbgs_verifier_oracle.py`](../../splash2_ocean_rbgs_verifier_oracle.py). [`workload.json`](workload.json) includes a hand-derived red-to-black dependency case, the maximum grid, and ABI error fixtures. [`verify_workload.py`](verify_workload.py) checks the fixtures and all port paths statically.

## Language ports

| Language | Port |
|---|---|
| C | [`c/o/splash2_ocean_rbgs.c`](../../../c/o/splash2_ocean_rbgs.c) |
| C3 | [`c3/o/splash2_ocean_rbgs.c3`](../../../c3/o/splash2_ocean_rbgs.c3) |
| C++ | [`cpp/o/splash2_ocean_rbgs.cpp`](../../../cpp/o/splash2_ocean_rbgs.cpp) |
| Elisa | [`elisa/o/splash2_ocean_rbgs.elisa`](../../../elisa/o/splash2_ocean_rbgs.elisa) |
| Mojo | [`mojo/o/splash2_ocean_rbgs.mojo`](../../../mojo/o/splash2_ocean_rbgs.mojo) |
| Nim | [`nim/o/splash2_ocean_rbgs.nim`](../../../nim/o/splash2_ocean_rbgs.nim) |
| Odin | [`odin/o/splash2_ocean_rbgs.odin`](../../../odin/o/splash2_ocean_rbgs.odin) |
| Rust | [`rust/o/splash2_ocean_rbgs.rs`](../../../rust/o/splash2_ocean_rbgs.rs) |
| V | [`v/o/splash2_ocean_rbgs.v`](../../../v/o/splash2_ocean_rbgs.v) |
| Zig | [`zig/o/splash2_ocean_rbgs.zig`](../../../zig/o/splash2_ocean_rbgs.zig) |
