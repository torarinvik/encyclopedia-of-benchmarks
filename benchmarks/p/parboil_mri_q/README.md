# Parboil MRI-Q direct nonuniform Fourier accumulation

`parboil_mri_q` is a bounded clean-room profile of Parboil's CPU `ComputePhiMagCPU` and `ComputeQCPU` routines. It computes the magnitude of each complex sample and accumulates the corresponding phase contribution at one spatial voxel. The work is a direct nonuniform 3D Fourier/Q calculation, not an FFT and not the MRI gridding benchmark.

## Contract

The exported symbol is `parboil_mri_q`, using the `i64_array_bytes_output` ABI.

- Input layout: `[numK, x_u, y_u, z_u, (Kx_u, Ky_u, Kz_u, phiR_u, phiI_u)*numK]`.
- `numK` is 1 through 4. Every remaining signed integer is in `[-1_000_000, 1_000_000]` and represents a real value scaled by `1e-6`. The exact input length is `4 + 5*numK` (maximum 24 values).
- Decode each component as `f32(f32(raw) / f32(1_000_000))`. Initialize `Qr` and `Qi` to binary32 zero.
- Match the source's two-pass shape: compute each `phiMag = f32(f32(phiR*phiR) + f32(phiI*phiI))` in a first pass over records, then process records in a second pass. Form `xyz` using separately rounded binary32 products `Kx*x`, `Ky*y`, `Kz*z`, followed by `(Kx*x + Ky*y) + Kz*z`; then calculate `phase = f32(6.2831853071795864769252867665590058f * xyz)`. Evaluate binary32 cosine and sine of `phase`; add `f32(phiMag*cos(phase))` and `f32(phiMag*sin(phase))` to `Qr` and `Qi` in record order, rounding each product and sum to binary32.
- Output the completed source recurrence as two signed 32-bit little-endian integers: `roundf(Qr*1000)` followed by `roundf(Qi*1000)`. Rounding is nearest with halfway values away from zero, matching C `roundf`. The profile's component bounds imply `phiMag <= 2` and at most four records, so neither result exceeds 8 in magnitude and saturation is not needed. This fixed-point projection is an explicit boundary after the source calculation; it avoids exposing host-libm last-bit differences in serialized float bytes.
- Success returns 8. Invalid input returns `-1`; null output or capacity below 8 returns `-2` without writes.

This retains both source kernels' arithmetic and the complete per-record Q accumulation while bounding the work to one voxel and at most four k-space records. It excludes scanner/data-file loading, the full spatial grid, allocations, CUDA launch/timing wrappers, and MRI reconstruction. The oracle implements the same recurrence independently and uses double-precision host sine/cosine followed by binary32 rounding; coarse Q1000 projection absorbs only the final host-libm differences.

## Source and rights

Pinned source: [`yuhc/gpu-parboil` commit `ccf3d3126f1754ca85528722f4ced5894ccb852b`](https://github.com/yuhc/gpu-parboil/tree/ccf3d3126f1754ca85528722f4ced5894ccb852b). The source routines are [`benchmarks/mri-q/src/cpu/computeQ.cc`](https://github.com/yuhc/gpu-parboil/blob/ccf3d3126f1754ca85528722f4ced5894ccb852b/benchmarks/mri-q/src/cpu/computeQ.cc) (`ComputePhiMagCPU`, lines 22–29; `ComputeQCPU`, lines 33–54). The benchmark description identifies the operation as Q-matrix computation for a 3D non-Cartesian MRI scanner configuration and cites Stone et al., “Accelerating Advanced MRI Reconstructions on GPUs,” Computing Frontiers, 2008.

The repository's Illinois Open Source License, copyright 2007–2011 Board of Trustees of the University of Illinois, is reproduced in full in [`LICENSE.txt`](LICENSE.txt). The ports are clean-room implementations of the documented operations and do not copy source text.

Independent oracle: [`benchmarks/parboil_mri_q_oracle.py`](../../parboil_mri_q_oracle.py). Workload cases include zero phase, a quarter-turn phase, magnitude preprocessing, invalid frames, and output-capacity errors.

## Ports

| Language | Port |
|---|---|
| C | [`parboil_mri_q.c`](../../../c/p/parboil_mri_q.c) |
| C3 | [`parboil_mri_q.c3`](../../../c3/p/parboil_mri_q.c3) |
| C++ | [`parboil_mri_q.cpp`](../../../cpp/p/parboil_mri_q.cpp) |
| Elisa | [`parboil_mri_q.elisa`](../../../elisa/p/parboil_mri_q.elisa) |
| Nim | [`parboil_mri_q.nim`](../../../nim/p/parboil_mri_q.nim) |
| Odin | [`parboil_mri_q.odin`](../../../odin/p/parboil_mri_q.odin) |
| Rust | [`parboil_mri_q.rs`](../../../rust/p/parboil_mri_q.rs) |
| V | [`parboil_mri_q.v`](../../../v/p/parboil_mri_q.v) |
| Zig | [`parboil_mri_q.zig`](../../../zig/p/parboil_mri_q.zig) |
