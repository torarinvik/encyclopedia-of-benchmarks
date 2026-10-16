# Bluestein arbitrary-length Fourier transform

This benchmark implements the arbitrary-length complex transform in the pinned Java `FFTBluestein` source. It uses Bluestein's chirp construction and FFT-based convolution, with the source's negative-angle forward transform convention. The benchmark domain uses integer real samples, so each input is treated as a complex value with zero imaginary part.

## Contract

The `i64_array_bytes_output` ABI packs `[n, x0, ..., x(n-1)]`. The length may be any integer from 1 through 8, the packed length must be exactly `1+n`, and each sample must be in `[-8, 8]`.

The output contains `n` complex bins as interleaved real and imaginary signed 64-bit integers. Each component is rounded half away from zero after multiplication by `1,000,000`, then encoded as little-endian two's-complement. Success returns `16*n` bytes. Malformed input returns `-1`; a null or undersized output buffer returns `-2`. The output buffer is at most 128 bytes.

The workload covers lengths 1, 2, 3, 5, 6, 7, and 8, including signed, impulse-like, and alternating samples. The oracle computes the direct DFT using the same negative-angle convention and quantization rule.

## Pinned source and ports

- Java [`FFTBluestein.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/FFTBluestein.java)

| Language | Source |
| --- | --- |
| C | [`c/f/fft_bluestein.c`](../../../c/f/fft_bluestein.c) |
| C3 | [`c3/f/fft_bluestein.c3`](../../../c3/f/fft_bluestein.c3) |
| C++ | [`cpp/f/fft_bluestein.cpp`](../../../cpp/f/fft_bluestein.cpp) |
| Elisa | [`elisa/f/fft_bluestein.elisa`](../../../elisa/f/fft_bluestein.elisa) |
| Nim | [`nim/f/fft_bluestein.nim`](../../../nim/f/fft_bluestein.nim) |
| Odin | [`odin/f/fft_bluestein.odin`](../../../odin/f/fft_bluestein.odin) |
| Rust | [`rust/f/fft_bluestein.rs`](../../../rust/f/fft_bluestein.rs) |
| V | [`v/f/fft_bluestein.v`](../../../v/f/fft_bluestein.v) |
| Zig | [`zig/f/fft_bluestein.zig`](../../../zig/f/fft_bluestein.zig) |

Run the integrated verifier with `python3 benchmarks/verify_i64_array_bytes_output.py --algorithm fft_bluestein --elisa-compiler ../Elisa-compiler/bin/elisac-stage1 --jobs 4`.
