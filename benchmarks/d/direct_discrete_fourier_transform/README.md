# Direct discrete Fourier transform

This package measures the defining direct summation method for a complex discrete Fourier transform. The Algorithm Archive Cooley–Tukey chapter presents the DFT as the transform matrix and direct nested sum before deriving faster factorizations. This profile evaluates each output bin independently in natural order, taking O(N²) arithmetic operations. It accepts every size from 1 through 64; the local radix-2 FFT package restricts N to powers of two and uses butterfly stages.

## Contract

The float64_slice_io input is [N, re0, im0, re1, im1, ..., re(N-1), im(N-1)]. N is an exactly represented integer in [1,64], the input length must equal 1+2N, and every component must be finite and lie in [-8,8]. The maximum valid input length is 129 doubles; 130 doubles are parseable so a trailing-word rejection is covered.

For frequency k in [0,N), the benchmark computes:

X[k] = sum(j=0..N-1) x[j] * exp(-2*pi*i*j*k/N)

where x[j]=re[j]+i*im[j]. Output contains [Re X[0], Im X[0], ..., Re X[N-1], Im X[N-1]] in natural frequency order. This is an unnormalized forward transform with the negative-exponent convention used by the Archive’s direct examples.

Malformed input returns -1. A null output pointer or capacity below 2N returns -2. Errors write nothing. The output bound is 128 float64 elements. The primary port computes each twiddle and accumulates its real and imaginary contributions in increasing sample-index order; it uses no algorithm workspace beyond scalar accumulators. For valid input, each output component has magnitude at most 64*sqrt(128) < 725. The comparison tolerances are absolute 1e-9 and relative 1e-12.

The package oracle is the direct defining sum. A second oracle evaluates the input polynomial at each Nth root of unity by complex Horner recurrence; it is structured independently from the nested summation.

## Provenance

The [Algorithm Archive Cooley–Tukey chapter](https://www.algorithm-archive.org/contents/cooley_tukey/cooley_tukey.html) gives the DFT matrix and direct nested-loop formula, then contrasts it with recursive and iterative FFT methods. Cooley and Tukey’s original paper, [“An Algorithm for the Machine Calculation of Complex Fourier Series”](https://doi.org/10.1090/S0025-5718-1965-0178586-1), is cited for the factored fast-transform distinction. The benchmark implementation and fixtures are original clean-room work.

## Ports

- [C](../../../c/d/direct_discrete_fourier_transform.c)
- [C3](../../../c3/d/direct_discrete_fourier_transform.c3)
- [C++](../../../cpp/d/direct_discrete_fourier_transform.cpp)
- [Elisa](../../../elisa/d/direct_discrete_fourier_transform.elisa)
- [Mojo](../../../mojo/d/direct_discrete_fourier_transform.mojo)
- [Nim](../../../nim/d/direct_discrete_fourier_transform.nim)
- [Odin](../../../odin/d/direct_discrete_fourier_transform.odin)
- [Rust](../../../rust/d/direct_discrete_fourier_transform.rs)
- [V](../../../v/d/direct_discrete_fourier_transform.v)
- [Zig](../../../zig/d/direct_discrete_fourier_transform.zig)

