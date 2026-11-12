# Imaginary-time split-operator method

This bounded profile follows the [Arcane Algorithm Archive's Split-Operator Method](https://www.algorithm-archive.org/contents/split-operator_method/split-operator_method.html). The article describes the Strang-split position/momentum/position recurrence and the imaginary-time variant for ground-state evolution. The ports and direct-DFT oracle here are clean-room implementations.

## Contract

Input is `[N, step_count, R[0..N), K[0..N), psi_re[0], psi_im[0], ..., psi_re[N-1], psi_im[N-1]]`. `N` is a power of two in `[2,64]`, and the step count is in `[0,8]`. `R` and `K` are supplied precomputed diagonal imaginary-time factors in `[0.25,1]`: `R[j] = exp(-V[j]*dt/2)` and `K[j] = exp(-T[k_j]*dt)`. Supplying the factors makes the bounded benchmark deterministic while keeping their construction separate from the evolution kernel. Momentum factors use standard radix-2 FFT order: frequencies `0` through `N/2-1`, followed by `-N/2` through `-1`.

The initial complex state must be nonzero and each real or imaginary component must lie in `[-1,1]`. The kernel normalizes the input state, then repeats: multiply by `R`, perform a forward DFT, multiply by `K`, perform an inverse DFT scaled by `1/N`, multiply by `R` again, and normalize. Output is the final complex state in interleaved real/imaginary order, with `sum(|psi[j]|^2)=1`. Invalid input returns `-1`; a null or undersized output returns `-2` without writes. The maximum input is 258 float64 values and the maximum output is 128 float64 values.

## Algorithm and reference

Each port uses an in-place iterative radix-2 Cooley–Tukey FFT for the forward and inverse transforms. The Strang order is the symmetric `R/2, K, R/2` evolution, which has local splitting error of order `dt^3` as described in the reference. This package benchmarks the full split-step recurrence and state normalization; it does not claim convergence to a continuum ground state for every factor table.

The [independent Python oracle](../../split_operator_imaginary_time_oracle.py) uses direct `O(N^2)` DFT and inverse-DFT sums rather than an FFT, for `O(step_count*N^2)` work. The suite compares floating outputs with absolute and relative tolerance `1e-10`. Workspace is `O(N)` with two fixed arrays for the complex state.

This is distinct from [`fast_fourier_transform`](../../f/fast_fourier_transform/README.md), which measures transform output alone, and from the general ODE integrators, which do not apply alternating diagonal operators in position and frequency space.

## Language ports

| Language | Source |
|---|---|
| C | [`c/s/split_operator_imaginary_time.c`](../../../c/s/split_operator_imaginary_time.c) |
| C3 | [`c3/s/split_operator_imaginary_time.c3`](../../../c3/s/split_operator_imaginary_time.c3) |
| C++ | [`cpp/s/split_operator_imaginary_time.cpp`](../../../cpp/s/split_operator_imaginary_time.cpp) |
| Elisa | [`elisa/s/split_operator_imaginary_time.elisa`](../../../elisa/s/split_operator_imaginary_time.elisa) |
| Mojo | [`mojo/s/split_operator_imaginary_time.mojo`](../../../mojo/s/split_operator_imaginary_time.mojo) |
| Nim | [`nim/s/split_operator_imaginary_time.nim`](../../../nim/s/split_operator_imaginary_time.nim) |
| Odin | [`odin/s/split_operator_imaginary_time.odin`](../../../odin/s/split_operator_imaginary_time.odin) |
| Rust | [`rust/s/split_operator_imaginary_time.rs`](../../../rust/s/split_operator_imaginary_time.rs) |
| V | [`v/s/split_operator_imaginary_time.v`](../../../v/s/split_operator_imaginary_time.v) |
| Zig | [`zig/s/split_operator_imaginary_time.zig`](../../../zig/s/split_operator_imaginary_time.zig) |
