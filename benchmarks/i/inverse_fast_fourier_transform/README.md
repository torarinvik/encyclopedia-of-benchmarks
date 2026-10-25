# Inverse fast Fourier transform

This benchmark follows the valid inverse function in the pinned Rust FFT module. It accepts complex frequency bins, applies the negative-angle radix-2 transform and divides by the input length once at the end. The source function returns only each transformed value's real component, which this contract preserves. The separately named pinned C++ inverse files were excluded from this benchmark because their scaled positive-angle twiddle recurrence does not implement this inverse transform.

## Contract

The `i64_array_bytes_output` ABI packs `[n, re0, im0, ..., re(n-1), im(n-1)]`. The bin count must be a power of two from 1 through 64, the packed array length must be exactly `1 + 2*n`, and each real or imaginary component must be in `[-1000, 1000]`.

The output contains `n` real components as signed 64-bit integers. Each component is rounded half away from zero after multiplication by `1,000,000`; integers are encoded in little-endian two's-complement order. Success returns `8*n` bytes. Malformed input returns `-1`; a null or undersized output buffer returns `-2`. With the component bound, the absolute real output is bounded by `sqrt(2)*1000`; the scaled i64 result remains safely below `1,414,213,563`.

The workload covers the pinned four-bin Rust example, a singleton, conjugate-symmetric and general complex inputs, DC-only and alternating-frequency signals, the maximum length, and malformed dimensions and components.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm inverse_fast_fourier_transform --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm inverse_fast_fourier_transform
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm inverse_fast_fourier_transform --languages rust
```

## Pinned source and ports

- Rust [`fast_fourier_transform.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/fast_fourier_transform.rs)
- LAC-DCC MiBench [`fourierf.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/telecomm-FFT/fourierf.c) also implements radix-2 inverse FFT. Its float32 complex-vector wrapper is not retained as another package for the same algorithm.

| Language | Source |
| --- | --- |
| C | [`c/i/inverse_fast_fourier_transform.c`](../../../c/i/inverse_fast_fourier_transform.c) |
| C3 | [`c3/i/inverse_fast_fourier_transform.c3`](../../../c3/i/inverse_fast_fourier_transform.c3) |
| C++ | [`cpp/i/inverse_fast_fourier_transform.cpp`](../../../cpp/i/inverse_fast_fourier_transform.cpp) |
| Elisa | [`elisa/i/inverse_fast_fourier_transform.elisa`](../../../elisa/i/inverse_fast_fourier_transform.elisa) |
| Nim | [`nim/i/inverse_fast_fourier_transform.nim`](../../../nim/i/inverse_fast_fourier_transform.nim) |
| Odin | [`odin/i/inverse_fast_fourier_transform.odin`](../../../odin/i/inverse_fast_fourier_transform.odin) |
| Rust | [`rust/i/inverse_fast_fourier_transform.rs`](../../../rust/i/inverse_fast_fourier_transform.rs) |
| V | [`v/i/inverse_fast_fourier_transform.v`](../../../v/i/inverse_fast_fourier_transform.v) |
| Zig | [`zig/i/inverse_fast_fourier_transform.zig`](../../../zig/i/inverse_fast_fourier_transform.zig) |
