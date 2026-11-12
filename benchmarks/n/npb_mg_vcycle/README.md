# Bounded NPB three-dimensional multigrid V-cycle

This package implements the recursive V-cycle correction operator defined for
NAS Parallel Benchmarks MG in RNR-94-007 §2.2.4. It uses a fixed periodic
4×4×4 fine grid, one 2×2×2 coarse grid, the report's 27-point trilinear
finite-element Laplacian, half-transpose restriction, trilinear interpolation,
and the `S(a)` smoother. The top-level solver performs one to four
residual-correction iterations, `r = f - A u` and `u = u + M r`.

The bounded `float64_slice_io` ABI accepts `[iterations, source_count,
x_0,y_0,z_0,value_0, ...]`. There are 0–8 unique point sources on the 4³
periodic grid; coordinates are exact integers in 0–3 and source values are
finite in [-4,4]. The right-hand side is zero elsewhere. Output is one binary64
value: the sum of the final solution in x-fast row-major order. Invalid input
returns `-1`; null output or capacity below one returns `-2` without writing.
The output comparison tolerance is `1e-9` absolute and relative.

This profile isolates the specified multigrid solver operation. It does not
reproduce NPB's large class grids, generated 20-point forcing, class-specific
verification outputs, or parallel communication. The 4³ bound still exercises a
full restriction, recursive coarse solve, interpolation, residual update, and
post-smoothing path.

## Distinction from local packages

[`doe_minigmg_restriction`](../../d/doe_minigmg_restriction/README.md)
computes only a cell-centered average over each disjoint 2×2×2 fine-grid block;
it has no residual equation, coarse correction, interpolation, smoother, or
cycle controller. [`splash2_ocean_rbgs`](../../o/splash2_ocean_rbgs/README.md)
is one 2-D red-black Gauss–Seidel sweep from a different screened-Poisson
operator and does not implement a 3-D multigrid cycle. Local Jacobi, Poisson,
and stencil packages update one grid or perform isolated same-grid kernels:
[`himenobmtxpa`](../../h/himenobmtxpa/README.md) is weighted point-Jacobi,
[`polybench_heat_3d`](../../h/heat_3d/README.md) is a fixed-boundary two-buffer
heat recurrence, [`parboil_stencil_laplacian`](../../p/parboil_stencil_laplacian/README.md)
is a fixed-boundary seven-point Laplacian update, and
[`doe_miniamr_stencil_average`](../../d/doe_miniamr_stencil_average/README.md)
is a same-grid 7- or 27-point average. They do not provide the NPB 27-point
operator together with its transfer pair and recursive cycle composition.

The primary oracle is [`npb_mg_vcycle_oracle.py`](../../npb_mg_vcycle_oracle.py).
The independent verifier constructs the transfer and stencil operators as
sparse matrices in [`npb_mg_vcycle_verifier_oracle.py`](../../npb_mg_vcycle_verifier_oracle.py).
Fixtures and static port/provenance checks are in this package's
[`workload.json`](workload.json) and [`verify_workload.py`](verify_workload.py).

## Ports

- C: [`c/n/npb_mg_vcycle.c`](../../../c/n/npb_mg_vcycle.c)
- C3: [`c3/n/npb_mg_vcycle.c3`](../../../c3/n/npb_mg_vcycle.c3)
- C++: [`cpp/n/npb_mg_vcycle.cpp`](../../../cpp/n/npb_mg_vcycle.cpp)
- Elisa: [`elisa/n/npb_mg_vcycle.elisa`](../../../elisa/n/npb_mg_vcycle.elisa)
- Mojo: [`mojo/n/npb_mg_vcycle.mojo`](../../../mojo/n/npb_mg_vcycle.mojo)
- Nim: [`nim/n/npb_mg_vcycle.nim`](../../../nim/n/npb_mg_vcycle.nim)
- Odin: [`odin/n/npb_mg_vcycle.odin`](../../../odin/n/npb_mg_vcycle.odin)
- Rust: [`rust/n/npb_mg_vcycle.rs`](../../../rust/n/npb_mg_vcycle.rs)
- V: [`v/n/npb_mg_vcycle.v`](../../../v/n/npb_mg_vcycle.v)
- Zig: [`zig/n/npb_mg_vcycle.zig`](../../../zig/n/npb_mg_vcycle.zig)

No program, test, build, compiler, benchmark, or checker was run while
preparing this profile.
