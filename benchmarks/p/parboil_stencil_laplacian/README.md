# Parboil seven-point Laplacian stencil

This package isolates Parboil's CPU `cpu_stencil` recurrence as a bounded
three-dimensional seven-point discrete Laplacian. It performs 1–4 steps on a
3×3×3 through 5×5×5 grid and keeps the boundary cells fixed. The profile
preserves the source's x-fast `Index3D` layout, x/y/z traversal order, and
six-neighbor accumulation order.

For each interior cell, the update is
`f32(f32(z+ + z- + y+ + y- + x+ + x-)*c1 - f32(center*c0))`, where
`c0=f32(1/6)` and `c1=f32(f32(1/6)/6)`. Each input cell is converted to
binary32, and arithmetic steps are rounded to binary32 without fused
multiply-add. Final binary32 cells are promoted to the float64-slice output.
Input is `[nx,ny,nz,steps,grid...]`, with x-fast flattened cells and values in
`[-8,8]`. Invalid input returns `-1`; null or undersized output returns `-2`
without modifying output. The maximum grid is 125 cells and workspace is 375
elements for two source buffers plus staged output.

The profile is a discrete Laplacian update. It is distinct from the local
heat-diffusion recurrence and from seven-point neighborhood averaging: its
center coefficient is negative, there is no center-value carry term, and the
six neighbor values have source-defined single-precision scaling.

## Source and rights

Pinned source: [`cpu_stencil`](https://github.com/yuhc/gpu-parboil/blob/ccf3d3126f1754ca85528722f4ced5894ccb852b/benchmarks/stencil/src/cpu/kernels.c#L11-L33),
with coefficient and iteration setup in
[`main.c`](https://github.com/yuhc/gpu-parboil/blob/ccf3d3126f1754ca85528722f4ced5894ccb852b/benchmarks/stencil/src/cpu/main.c#L52-L110)
and x-fast indexing in
[`common.h`](https://github.com/yuhc/gpu-parboil/blob/ccf3d3126f1754ca85528722f4ced5894ccb852b/benchmarks/stencil/src/cpu/common.h#L9-L12).
The source is pinned to commit `ccf3d3126f1754ca85528722f4ced5894ccb852b`.
The ports are independently written. The Illinois Open Source License and
source attribution are reproduced in [`LICENSE.txt`](LICENSE.txt).

See [`workload.json`](workload.json) and the independent
[`oracle`](../../parboil_stencil_laplacian_oracle.py).

## Ports

- C: [`c/p/parboil_stencil_laplacian.c`](../../../c/p/parboil_stencil_laplacian.c)
- C3: [`c3/p/parboil_stencil_laplacian.c3`](../../../c3/p/parboil_stencil_laplacian.c3)
- C++: [`cpp/p/parboil_stencil_laplacian.cpp`](../../../cpp/p/parboil_stencil_laplacian.cpp)
- Elisa: [`elisa/p/parboil_stencil_laplacian.elisa`](../../../elisa/p/parboil_stencil_laplacian.elisa)
- Nim: [`nim/p/parboil_stencil_laplacian.nim`](../../../nim/p/parboil_stencil_laplacian.nim)
- Odin: [`odin/p/parboil_stencil_laplacian.odin`](../../../odin/p/parboil_stencil_laplacian.odin)
- Rust: [`rust/p/parboil_stencil_laplacian.rs`](../../../rust/p/parboil_stencil_laplacian.rs)
- V: [`v/p/parboil_stencil_laplacian.v`](../../../v/p/parboil_stencil_laplacian.v)
- Zig: [`zig/p/parboil_stencil_laplacian.zig`](../../../zig/p/parboil_stencil_laplacian.zig)

No project code, ports, tests, builds, or validators were run as part of this
static package preparation.
