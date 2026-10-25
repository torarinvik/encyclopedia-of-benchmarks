# Radix-2 fast Fourier transform

This benchmark ports the forward radix-2 transform in the pinned C++ and Rust sources. The transform uses the source's positive twiddle angle, `exp(+2πi/n)`, and returns the bins in natural frequency order. It accepts real integer samples, represented as zero-imaginary complex values.

## Contract

The `i64_array_bytes_output` ABI packs `[n, x0, ..., x(n-1)]`. The sample count must be a power of two from 1 through 64, the packed array length must be exactly `1 + n`, and each sample must be in `[-1000, 1000]`.

The output contains `n` complex bins as interleaved real and imaginary signed 64-bit integers. Each component is rounded half away from zero after multiplication by `1,000,000`; integers are encoded in little-endian two's-complement order. Success returns `16*n` bytes. Malformed input returns `-1`; a null or undersized output buffer returns `-2`. The largest result component is bounded by `64,000,000,000` in the scaled domain.

The workload includes the pinned two- and four-sample examples, singleton and impulse inputs, alternating and signed samples, the maximum length, maximum sample magnitude, and malformed lengths and values.

## Pinned sources and ports

- C++ [`fast_fourier_transform.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/fast_fourier_transform.cpp)
- C++ (additional repository) [`fast_fourier_transform.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/numerical_methods/fast_fourier_transform.cpp)
- Rust [`fast_fourier_transform.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/fast_fourier_transform.rs)
- LAC-DCC MiBench [`fourierf.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/telecomm-FFT/fourierf.c) uses the same radix-2 forward FFT algorithm over complex binary32 samples; the MiBench launcher is crosswalked to the forward and inverse FFT packages rather than duplicated.

| Language | Source |
| --- | --- |
| C | [`c/f/fast_fourier_transform.c`](../../../c/f/fast_fourier_transform.c) |
| C3 | [`c3/f/fast_fourier_transform.c3`](../../../c3/f/fast_fourier_transform.c3) |
| C++ | [`cpp/f/fast_fourier_transform.cpp`](../../../cpp/f/fast_fourier_transform.cpp) |
| Elisa | [`elisa/f/fast_fourier_transform.elisa`](../../../elisa/f/fast_fourier_transform.elisa) |
| Nim | [`nim/f/fast_fourier_transform.nim`](../../../nim/f/fast_fourier_transform.nim) |
| Odin | [`odin/f/fast_fourier_transform.odin`](../../../odin/f/fast_fourier_transform.odin) |
| Rust | [`rust/f/fast_fourier_transform.rs`](../../../rust/f/fast_fourier_transform.rs) |
| V | [`v/f/fast_fourier_transform.v`](../../../v/f/fast_fourier_transform.v) |
| Zig | [`zig/f/fast_fourier_transform.zig`](../../../zig/f/fast_fourier_transform.zig) |
