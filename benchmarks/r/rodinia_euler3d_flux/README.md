# Rodinia Euler3D single-cell flux

`rodinia_euler3d_flux` isolates the source `cuda_compute_flux` operation in Rodinia's Euler3D finite-volume solver. It computes the five conserved flux components for one cell by visiting its four faces in source order. This is a kernel profile, not the 2000-iteration mesh solver, data-file reader, CUDA launch wrapper, or timing path.

## Contract

The ABI is `i64_array_scalar`, symbol `rodinia_euler3d_flux`, with exactly 41 signed-i64 words:

```text
[center rho,mx,my,mz,rhoE as f32 bits,
 for each of four faces in source order:
   kind,nx,ny,nz as [i64 kind, f32 bit patterns],
   neighbor rho,mx,my,mz,rhoE as f32 bit patterns]
```

Kinds match the kernel branches: `0` is a real neighbor, `-1` is the wing wall, and `-2` is the far-field boundary. The five neighbor state words remain present and valid for every face; boundary branches ignore them. Each float is supplied by its raw IEEE-754 binary32 bits carried in a nonnegative i64. Density is in [0.5, 2], momentum components in [-1, 1], density energy in [1, 5], and each normal component in [-1, 1]. Center, neighbor, and derived far-field states must have positive pressure. Other face kinds, malformed frames, and non-finite recurrence results return -1.

For a real neighbor the profile preserves the source's artificial-viscosity update followed by the x, y, and z centered-flux updates. A wing face adds pressure times the face normal to momentum flux. A far-field face uses the source constants (gamma 1.4f, Mach 1.2f, zero angle, density 1.4f, pressure 1.0f) and its precomputed far-field flux contributions. The source's four-face order and component update order are preserved. The equations use binary32 operations and stores, including the source's float constants and `sqrtf` operations.

The result converts each binary32 flux component to binary64, multiplies by 1000, rounds half values away from zero, then sums the five results weighted by component index plus one. Component order is density, momentum x/y/z, then density energy. This projection is deterministic and makes all five flux outputs observable.

## Provenance and rights

- Pinned source: [utcs-scea/rodinia `cuda/cfd/euler3d.cu`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/cfd/euler3d.cu) at commit `f30e63663cfb114939a15c7ffc4ae112055ae6a8`; source launch and dataset notes are in [`cuda/cfd/run`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/cfd/run) and [`cuda/cfd/README`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/cfd/README).
- The source identifies Andrew Corrigan's AIAA-2009-4001 implementation and says permission was granted to include it under Rodinia's license. The complete pinned Rodinia BSD-3-Clause notice and citation list are in [`LICENSE.txt`](LICENSE.txt). These ports are independent implementations of the equations and contain no copied kernel text.
- The static workload includes one hand-derived uniform-state cancellation fixture plus invalid-frame cases. The independent [Python oracle](../../rodinia_euler3d_flux_oracle.py) covers the bounded recurrence.

