# Parboil cutcp cutoff-potential lattice kernel

`parboil_cutcp` is a bounded clean-room profile of Parboil's CPU
`cpu_compute_cutoff_potential_lattice` kernel. It spreads short-range
electrostatic potential from point charges onto a small regular 3D lattice.
The kernel uses spatial cell hashing to order charges, visits only a cutoff
box, applies the source's cylindrical prefilter, and accumulates the tapered
`q/r` potential. This is distinct from direct MRI-Q Fourier accumulation,
TPACF pair histograms, generic N-body force updates, and lattice stencils.

## Contract

The exported symbol is `parboil_cutcp`, using the
`i64_array_bytes_output` ABI.

- Input layout: `[nx,ny,nz,atom_count,xlo_u,ylo_u,zlo_u,h_u,cutoff_u,
  (ix,iy,iz,charge_u)*atom_count]`.
- Each grid dimension is 2–4 and `atom_count` is 1–4. The exact input length
  is `9 + 4*atom_count` (maximum 25 signed 64-bit values).
- `xlo_u`, `ylo_u`, and `zlo_u` are integer lattice origins in Q1e-6 units,
  bounded to `[-16_000_000,16_000_000]` and required to be multiples of
  1_000_000. `h_u` is one of 1_000_000, 2_000_000, 3_000_000, or 4_000_000;
  `cutoff_u` represents a source cutoff from 0.25 through 4.0. Decode scaled
  values as `f32(f32(raw)/f32(1_000_000))`.
- Each atom record gives a cell index `ix,iy,iz` in `[0,dimension-2]` and
  charge in `[-1_000_000,1_000_000]`. The source atom coordinate is the
  half-cell center `origin + (index + 0.5)*h`, evaluated in binary32. This
  bounded coordinate form ensures all contributing atom-to-lattice distances
  are nonzero without adding a source-incompatible near-field skip or error.
- The profile computes a zero-initialized lattice, as the pinned CPU launcher
  does. It preserves 4-unit cell extents, source min/max-based cell counts,
  ascending cell traversal, head insertion (therefore reverse atom order
  within a cell), q==0 insertion skipping, clipped box bounds, source loop and
  accumulation order, the `dydz2 >= cutoff²` cylinder check, and the strict
  `r² < cutoff²` contribution rule. Each contribution follows the source
  binary32 sequence `q * (1/sqrtf(r²)) * s * s`, where
  `s = 1 - r²/cutoff²`.
- Output is one signed little-endian i32 per lattice cell, in source row-major
  `(z,y,x)` order, each representing the completed binary32 potential rounded
  to nearest with halfway values away from zero after multiplication by 1000.
  Q1000 is the explicit serialization boundary; the source computation remains
  binary32. The domain bounds keep every serialized value in signed-i32 range.
- Success returns the number of output bytes (`4*nx*ny*nz`, at most 256).
  Invalid input returns `-1`; a null or undersized output buffer returns `-2`
  without writes.

The package covers `cpu_compute_cutoff_potential_lattice` and its geometric
hashing path. Atom-file parsing, launcher timing, the separate
`remove_exclusions` pass, and the output-file summary are outside this profile.
The original launcher defaults to spacing 0.5 and cutoff 12; the bounded
profile narrows these to integer spacing 1–4 and cutoff 0.25–4 while invoking
the same parameterized kernel recurrence. The independent oracle follows the
bounded source traversal and exposes all valid inputs up to four atoms for
generated verifier corpus coverage.

## Source and rights

Pinned source: [`yuhc/gpu-parboil` commit
`ccf3d3126f1754ca85528722f4ced5894ccb852b`](https://github.com/yuhc/gpu-parboil/tree/ccf3d3126f1754ca85528722f4ced5894ccb852b).
The principal kernel is [`benchmarks/cutcp/src/base/cutcpu.c`](https://github.com/yuhc/gpu-parboil/blob/ccf3d3126f1754ca85528722f4ced5894ccb852b/benchmarks/cutcp/src/base/cutcpu.c)
(`cpu_compute_cutoff_potential_lattice`). Supporting behavior is documented
by `readatom.c` (`get_atom_extent`), `cutoff.h`, `main.c`, and
`benchmarks/cutcp/DESCRIPTION`. The source description identifies the workload
as short-range electrostatic potential induced by point charges on a 3D
volume and cites Rodrigues et al., “GPU Acceleration of Cutoff Pair Potential
for Molecular Modeling Applications,” Computing Frontiers, 2008.

The repository's Illinois Open Source License is reproduced in full in
[`LICENSE.txt`](LICENSE.txt). These ports are clean-room implementations of
the documented kernel behavior; no source comments or code were copied.

Independent oracle: [`benchmarks/parboil_cutcp_oracle.py`](../../parboil_cutcp_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`parboil_cutcp.c`](../../../c/p/parboil_cutcp.c) |
| C3 | [`parboil_cutcp.c3`](../../../c3/p/parboil_cutcp.c3) |
| C++ | [`parboil_cutcp.cpp`](../../../cpp/p/parboil_cutcp.cpp) |
| Elisa | [`parboil_cutcp.elisa`](../../../elisa/p/parboil_cutcp.elisa) |
| Nim | [`parboil_cutcp.nim`](../../../nim/p/parboil_cutcp.nim) |
| Odin | [`parboil_cutcp.odin`](../../../odin/p/parboil_cutcp.odin) |
| Rust | [`parboil_cutcp.rs`](../../../rust/p/parboil_cutcp.rs) |
| V | [`parboil_cutcp.v`](../../../v/p/parboil_cutcp.v) |
| Zig | [`parboil_cutcp.zig`](../../../zig/p/parboil_cutcp.zig) |
