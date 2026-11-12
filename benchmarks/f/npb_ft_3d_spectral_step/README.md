# NAS FT 3-D spectral time step

This package implements a bounded sequential profile of the FT kernel described in NASA's [NAS Parallel Benchmarks report RNR-94-007](https://www.nas.nasa.gov/assets/nas/pdf/techreports/1994/rnr-94-007.pdf), §2.2.5. The profile carries out a complex 3-D forward transform, repeated spectral exponential updates from the fixed initial spectrum, inverse transforms, and the per-step sampled complex checksums. It uses three radix-2 axis passes internally; it does not introduce another standalone 1-D FFT benchmark.

The local [`fast_fourier_transform`](../fast_fourier_transform/README.md) package measures a single 1-D radix-2 transform. [`splash2_fft_six_step`](../splash2_fft_six_step/README.md) measures a 1-D transpose-aware schedule. [`split_operator_imaginary_time`](../split_operator_imaginary_time/README.md) repeats a 1-D position/momentum/position evolution with normalization. FT is distinct because its workload is a 3-D complex field evolved from one fixed spectrum by an isotropic frequency-space exponential, followed by sampled 3-D checksums.

## Contract

The `float64_slice_io` input is `[side, step_count, re0, im0, re1, im1, ...]`. Complex samples fill a cubic `side × side × side` array in row-major order, with the last axis varying fastest. `side` is 2 or 4, and `step_count` is 1 through 6. Each finite input component must be in `[-1,1]`. Input length must be exactly `2 + 2*side^3`; the largest valid frame has 130 values.

Each axis uses the forward DFT convention `exp(-2πi·index·frequency/side)`. Signed spectral coordinates map indices `0..side/2` to nonnegative frequencies and higher indices to `index-side`. The profile computes the 3-D forward transform `V` once. For steps `t=1..step_count`, it forms `W[k] = V[k] * exp(-4π² * 10^-6 * t * (kx²+ky²+kz²))`, computes the inverse 3-D transform with total normalization `1/side^3`, then sums 64 samples at `(j mod side, 3j mod side, 5j mod side)` using one-based `j=1..64`. The emitted complex checksum is divided by `side^3`; output is interleaved real and imaginary checksums in time-step order.

This bounded contract supplies the initial field explicitly instead of generating the report's pseudorandom field, caps the cube at side 4, and uses 64 checksum samples so each call remains small. It retains the transform/evolve/checksum recurrence and the spectral multiplier; it does not claim to reproduce NPB Class A or B sizes, parallel decomposition, communication, or timing rules. Invalid input returns `-1`; a null or undersized output returns `-2` without writes. Success returns `2*step_count`; compare values with absolute and relative tolerance `1e-9`.

The primary oracle computes each full 3-D DFT from its defining six nested sums in [`../../npb_ft_3d_spectral_step_oracle.py`](../../npb_ft_3d_spectral_step_oracle.py). The independent checker oracle performs three separable direct-DFT axis passes in [`../../npb_ft_3d_spectral_step_verifier_oracle.py`](../../npb_ft_3d_spectral_step_verifier_oracle.py). [`workload.json`](workload.json) covers a constant complex cube, a nonzero Nyquist mode, and ABI errors. [`verify_workload.py`](verify_workload.py) statically checks the contract and ports.

## Rights and provenance

The source is the algorithmic description in NASA Ames Research Center's RNR-94-007, “The NAS Parallel Benchmarks,” March 1994, FT kernel section. The ports are clean-room implementations of the mathematical transform and update recurrence. They do not copy an upstream implementation, comments, tables, or prose. No third-party source license is asserted for these new files.

## Language ports

| Language | Source |
|---|---|
| C | [`c/f/npb_ft_3d_spectral_step.c`](../../../c/f/npb_ft_3d_spectral_step.c) |
| C3 | [`c3/f/npb_ft_3d_spectral_step.c3`](../../../c3/f/npb_ft_3d_spectral_step.c3) |
| C++ | [`cpp/f/npb_ft_3d_spectral_step.cpp`](../../../cpp/f/npb_ft_3d_spectral_step.cpp) |
| Elisa | [`elisa/f/npb_ft_3d_spectral_step.elisa`](../../../elisa/f/npb_ft_3d_spectral_step.elisa) |
| Mojo | [`mojo/f/npb_ft_3d_spectral_step.mojo`](../../../mojo/f/npb_ft_3d_spectral_step.mojo) |
| Nim | [`nim/f/npb_ft_3d_spectral_step.nim`](../../../nim/f/npb_ft_3d_spectral_step.nim) |
| Odin | [`odin/f/npb_ft_3d_spectral_step.odin`](../../../odin/f/npb_ft_3d_spectral_step.odin) |
| Rust | [`rust/f/npb_ft_3d_spectral_step.rs`](../../../rust/f/npb_ft_3d_spectral_step.rs) |
| V | [`v/f/npb_ft_3d_spectral_step.v`](../../../v/f/npb_ft_3d_spectral_step.v) |
| Zig | [`zig/f/npb_ft_3d_spectral_step.zig`](../../../zig/f/npb_ft_3d_spectral_step.zig) |
