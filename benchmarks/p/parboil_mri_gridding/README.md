# Parboil MRI Cartesian gridding

`parboil_mri_gridding` isolates Parboil's CPU `gridding_Gold` kernel. Each
already grid-mapped non-Cartesian MRI sample contributes a Kaiser-Bessel weight
to the nearby voxels of a small 3D grid, accumulating complex values and a
sample-density field. This is distinct from Parboil MRI-Q, which forms complex
Fourier/Q values from phase recurrences over k-space records.

## Contract

- Exported symbol: `parboil_mri_gridding`; ABI: `i64_array_scalar`.
- Input is `[sample_count, (kx, ky, kz, real, imag, sdc)...]` with exact length
  `1 + 6*sample_count`, and `sample_count` in `0..4`.
- All sample fields use signed fixed-point units of `1e-6`. Coordinates must be
  exactly `0`, `1`, or `2` grid units. Real and imaginary components are in
  `[-1,1]`; density compensation (`sdc`) is in `[0,1]`.
- The profile uses a fixed 3×3×3 grid, kernel width `2.5f`, oversample
  `0.608933f`, and the source's non-LUT path. The selected positive oversample
  makes the source beta small enough that hand-derived Q1000 fixtures remain
  stable while retaining the full polynomial-kernel and gridding operations.
  Input coordinates are already in the grid-coordinate domain after the
  source's `readSampleData` scaling/floor step; acquisition-file parsing and
  that coordinate conversion are outside the contract.
- The source's strict spherical cutoff is applied in z, then y, then x order.
  A sample with both complex components zero, or with `sdc==0`, is skipped.
  For every accepted voxel, the source-order Kaiser-Bessel polynomial computes
  the weight, complex values are accumulated in sample order, and density is
  incremented once.
- Every arithmetic store in the kernel recurrence is binary32. The beta
  expression preserves the source's binary32 parameter arithmetic followed
  by binary64 operations from its unsuffixed `0.5`, `0.8`, `PI`, and `sqrt`
  expressions. The polynomial uses its listed binary32 coefficients and
  source-order multiply/add steps. This profile assumes no reassociation or
  fused multiply-add. Different historical compiler math settings may affect
  low bits.
- The result is the signed-i64 checksum
  `sum((voxel_index+1) * (real_q1000 + imag_q1000 + density_count))` over all
  27 row-major voxels (`x` fastest). Real and imaginary values are rounded to
  nearest integer with ties away from zero after multiplication by 1000;
  density is an exact integer for this bound. The maximum absolute result is
  3,028,536. Invalid input returns `-1`.
- Maximum input length is 25 signed-i64 words. The three 27-element f32
  accumulation arrays require 324 bytes of workspace.

The one-sample center fixture touches the center voxel and its six axial
neighbors. With the fixed profile parameters, the source kernel weights at
distance zero and one both quantize to Q1000 value 1000; the fixture checksum
is therefore `501 * (5+11+13+14+15+17+23) = 49,098`. The oracle uses a
voxel-major gather over samples rather than the ports' sample-major neighborhood
scatter.

[`workload.json`](workload.json) includes center and corner neighborhoods,
multiple overlapping samples, skipped samples, and invalid coordinates.

## Source and rights

Pinned source: [`yuhc/gpu-parboil` commit
`ccf3d3126f1754ca85528722f4ced5894ccb852b`](https://github.com/yuhc/gpu-parboil/tree/ccf3d3126f1754ca85528722f4ced5894ccb852b).
The scalar recurrence is in
[`benchmarks/mri-gridding/src/cuda/CPU_kernels.c`](https://github.com/yuhc/gpu-parboil/blob/ccf3d3126f1754ca85528722f4ced5894ccb852b/benchmarks/mri-gridding/src/cuda/CPU_kernels.c),
especially `kernel_value_CPU` and `gridding_Gold`. The sample layout and
parameters are in
[`UDTypes.h`](https://github.com/yuhc/gpu-parboil/blob/ccf3d3126f1754ca85528722f4ced5894ccb852b/benchmarks/mri-gridding/src/cuda/UDTypes.h);
the launcher and preprocessing are in
[`main.c`](https://github.com/yuhc/gpu-parboil/blob/ccf3d3126f1754ca85528722f4ced5894ccb852b/benchmarks/mri-gridding/src/base/main.c).
The pinned Parboil repository includes the Illinois Open Source License; its
full text is reproduced in [`LICENSE.txt`](LICENSE.txt). These ports are
clean-room implementations of the bounded profile.

Independent oracle: [`benchmarks/parboil_mri_gridding_oracle.py`](../../parboil_mri_gridding_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`parboil_mri_gridding.c`](../../../c/p/parboil_mri_gridding.c) |
| C3 | [`parboil_mri_gridding.c3`](../../../c3/p/parboil_mri_gridding.c3) |
| C++ | [`parboil_mri_gridding.cpp`](../../../cpp/p/parboil_mri_gridding.cpp) |
| Elisa | [`parboil_mri_gridding.elisa`](../../../elisa/p/parboil_mri_gridding.elisa) |
| Nim | [`parboil_mri_gridding.nim`](../../../nim/p/parboil_mri_gridding.nim) |
| Odin | [`parboil_mri_gridding.odin`](../../../odin/p/parboil_mri_gridding.odin) |
| Rust | [`parboil_mri_gridding.rs`](../../../rust/p/parboil_mri_gridding.rs) |
| V | [`parboil_mri_gridding.v`](../../../v/p/parboil_mri_gridding.v) |
| Zig | [`parboil_mri_gridding.zig`](../../../zig/p/parboil_mri_gridding.zig) |
