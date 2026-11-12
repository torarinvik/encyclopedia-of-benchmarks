# SPLASH-2 six-step FFT

This package implements the bounded complex forward transform used by the SPLASH-2 FFT kernel. It preserves the six-step data flow: transpose, one dimension of radix-2 row transforms, cross-dimension twiddle multiplication, transpose, the second dimension of row transforms, and a final transpose into natural frequency order. The standalone package omits the original processor scheduling and cache-specific transpose blocking.

The local [`fast_fourier_transform`](../fast_fourier_transform/README.md) package computes the same transform with an iterative in-place radix-2 bit-reversal and butterfly schedule. SPLASH-2 instead reshapes the input as a square matrix and explicitly moves data between dimensions three times. The twiddle multiplication and transposes change the memory-access profile, so this is a distinct benchmark algorithm profile. The SPLASH-2 source uses the negative-exponent forward convention; the local radix-2 package documents its own positive twiddle convention.

## Contract

The `float64_slice_io` input is `[side, re0, im0, re1, im1, ...]`, with samples in row-major matrix order. `side` is one of `{2,4,8}`, giving transform lengths 4, 16, or 64. Every real and imaginary component must be finite and in `[-8,8]`. The exact input length is `1 + 2*side*side`, at most 129 values; 130 values are parseable for an extra-value rejection case.

The forward convention is `X[k] = sum_j x[j] * exp(-2*pi*i*j*k/N)`. The six-step schedule interprets the vector as a `side`-by-`side` matrix: transpose it; apply a length-`side` forward radix-2 FFT to each row; multiply element `(row,column)` by `exp(-2*pi*i*row*column/N)`; transpose; apply the row FFTs again; transpose once more. Flatten the final matrix row-major to emit `N` complex bins in natural one-dimensional frequency order, as interleaved real and imaginary `float64` values.

Invalid input, malformed framing, or a null input pointer returns `-1` before output checks. A null output pointer or output capacity below `2*N` returns `-2` without writes. Success returns `2*N`; compare values with absolute tolerance `1e-9` and relative tolerance `1e-12`.

The primary oracle computes the direct DFT in [`../../splash2_fft_six_step_oracle.py`](../../splash2_fft_six_step_oracle.py). The structurally independent checker oracle uses naive direct row sums in [`../../splash2_fft_six_step_verifier_oracle.py`](../../splash2_fft_six_step_verifier_oracle.py), without the radix-2 butterflies. [`workload.json`](workload.json) includes a nontrivial complex twiddle case, an impulse, the maximum-side case, and ABI error fixtures. [`verify_workload.py`](verify_workload.py) statically checks the contract and ports.

## Provenance

SPLASH-2's [FFT source](https://github.com/staceyson/splash2/blob/be64f8e4840fc29ff4c076c3f747e27fdb55ac68/codes/kernels/fft/fft.C) labels its method a six-step FFT, and its [program README](https://github.com/staceyson/splash2/blob/be64f8e4840fc29ff4c076c3f747e27fdb55ac68/codes/kernels/fft/README.fft) cites Bailey's hierarchical-memory FFT and the Woo, Singh, and Hennessy six-step implementation paper. The package ports use the algorithmic description and write a bounded sequential implementation; they do not copy the upstream implementation.

## Language ports

| Language | Port |
|---|---|
| C | [`c/f/splash2_fft_six_step.c`](../../../c/f/splash2_fft_six_step.c) |
| C3 | [`c3/f/splash2_fft_six_step.c3`](../../../c3/f/splash2_fft_six_step.c3) |
| C++ | [`cpp/f/splash2_fft_six_step.cpp`](../../../cpp/f/splash2_fft_six_step.cpp) |
| Elisa | [`elisa/f/splash2_fft_six_step.elisa`](../../../elisa/f/splash2_fft_six_step.elisa) |
| Mojo | [`mojo/f/splash2_fft_six_step.mojo`](../../../mojo/f/splash2_fft_six_step.mojo) |
| Nim | [`nim/f/splash2_fft_six_step.nim`](../../../nim/f/splash2_fft_six_step.nim) |
| Odin | [`odin/f/splash2_fft_six_step.odin`](../../../odin/f/splash2_fft_six_step.odin) |
| Rust | [`rust/f/splash2_fft_six_step.rs`](../../../rust/f/splash2_fft_six_step.rs) |
| V | [`v/f/splash2_fft_six_step.v`](../../../v/f/splash2_fft_six_step.v) |
| Zig | [`zig/f/splash2_fft_six_step.zig`](../../../zig/f/splash2_fft_six_step.zig) |
