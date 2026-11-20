# Stockham autosort radix-2 FFT

This package computes one bounded complex forward DFT with the radix-2
Stockham autosort schedule. Each stage reads one buffer and writes the other;
the two buffers exchange roles between stages. The stage mapping interleaves
the butterfly outputs so the final bins are in natural frequency order without
a separate bit-reversal pass.

## Contract

The `float64_slice_io` input is `[n, re0, im0, re1, im1, ...]`. `n` is an exact
power of two from 1 through 64. Every sample component must be finite and in
`[-8,8]`; the input length must equal `1+2*n`. The forward transform uses
`X[k] = sum_j x[j] * exp(-2*pi*i*j*k/n)`.

Output is `2*n` float64 values in natural order, interleaved as
`[re(X0),im(X0),...,re(X(n-1)),im(X(n-1))]`. Malformed or null input returns
`-1`. A null output or capacity below `2*n` returns `-2` without writes.
Comparisons use absolute tolerance `1e-9` and relative tolerance `1e-12`.
The maximum valid input has 129 values, maximum parseable input has 130, and
the two bounded ping-pong buffers use 256 float64 workspace elements.

For `n=1` the input is returned as its sole frequency bin. For larger sizes,
stage stride doubles from one to `n/2`. At stage stride `s`, source positions
`j` and `j+n/2` are multiplied by the radix-2 twiddle indexed by `j mod s`;
the sum and difference are written to their interleaved stage destinations.
The running time is O(n log n), with O(n) scratch space.

## Provenance and distinctness

Thomas G. Stockham, Jr., “High-speed convolution and correlation,” AFIPS '66
Spring Joint Computer Conference, pp. 229–233 (1966),
[DOI 10.1145/1464182.1464209](https://doi.org/10.1145/1464182.1464209).
The algorithm description is used as mathematical provenance; no source code,
comments, examples, or protected prose were copied. See [`RIGHTS.md`](RIGHTS.md).

The local [`fast_fourier_transform`](../fast_fourier_transform/README.md)
uses an in-place radix-2 schedule with a bit-reversal permutation. The local
[`splash2_fft_six_step`](../splash2_fft_six_step/README.md) reshapes the input
into a two-dimensional square and applies a six-step transpose schedule.
Stockham's alternating out-of-place stages and embedded autosort form a
separate data-movement profile.

[`primary_oracle.py`](primary_oracle.py) mirrors the stage mapping.
[`independent_oracle.py`](independent_oracle.py) evaluates the direct DFT.
The package-local workload verifier checks both references and the ten source
paths without compiling or executing a language port.

| Language | Port |
|---|---|
| C | [`c/s/stockham_autosort_radix2_fft.c`](../../../c/s/stockham_autosort_radix2_fft.c) |
| C3 | [`c3/s/stockham_autosort_radix2_fft.c3`](../../../c3/s/stockham_autosort_radix2_fft.c3) |
| C++ | [`cpp/s/stockham_autosort_radix2_fft.cpp`](../../../cpp/s/stockham_autosort_radix2_fft.cpp) |
| Elisa | [`elisa/s/stockham_autosort_radix2_fft.elisa`](../../../elisa/s/stockham_autosort_radix2_fft.elisa) |
| Mojo | [`mojo/s/stockham_autosort_radix2_fft.mojo`](../../../mojo/s/stockham_autosort_radix2_fft.mojo) |
| Nim | [`nim/s/stockham_autosort_radix2_fft.nim`](../../../nim/s/stockham_autosort_radix2_fft.nim) |
| Odin | [`odin/s/stockham_autosort_radix2_fft.odin`](../../../odin/s/stockham_autosort_radix2_fft.odin) |
| Rust | [`rust/s/stockham_autosort_radix2_fft.rs`](../../../rust/s/stockham_autosort_radix2_fft.rs) |
| V | [`v/s/stockham_autosort_radix2_fft.v`](../../../v/s/stockham_autosort_radix2_fft.v) |
| Zig | [`zig/s/stockham_autosort_radix2_fft.zig`](../../../zig/s/stockham_autosort_radix2_fft.zig) |
