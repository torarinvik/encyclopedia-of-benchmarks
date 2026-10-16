# FFT linear convolution

This benchmark ports TheAlgorithms/Java's `ConvolutionFFT.convolutionFFT` method. It pads two nonempty real signals to the full linear-convolution length, lets the helper FFT round that length up to a power of two, multiplies the spectra, applies the inverse FFT scaling, and trims the padded tail. The implementation uses the source's iterative radix-2 Cooley–Tukey butterflies and bit-reversal order.

## Contract

- The `i64_array_bytes_output` ABI packs `[a_count, b_count, a_fixed..., b_fixed...]`. Each count is in `1..=64`; packed length is exactly `2 + a_count + b_count`. Each signed sample `q` in `[-64, 64]` represents the real binary64 value `q / 16`. Imaginary input parts are zero.
- The result has `a_count + b_count - 1` complex coefficients. Output bytes contain each coefficient's real part followed by its imaginary part, both as little-endian IEEE-754 binary64 values.
- The mathematical result is full linear convolution in increasing output-index order. Since FFT arithmetic is approximate, the workload compares both components with absolute tolerance `1e-9` and relative tolerance `1e-12`.
- Invalid packing or out-of-domain values return `-1`. A valid input with a null or undersized output buffer returns `-2`; success returns the output byte length. The maximum output is 127 complex coefficients (2,032 bytes).
- Empty signals are excluded because the pinned method computes `a.size() + b.size() - 1` and its padding/trim logic does not define an empty-signal result.

## Pinned source

- Java [`ConvolutionFFT.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/ConvolutionFFT.java)
- Java helper [`FFT.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/FFT.java)

The direct [`convolution`](../convolution/README.md) benchmark uses nested loops and exact integer output; Python [`convolve_1d`](../convolve_1d/README.md) returns a centered, signal-length result. This package measures the Java FFT implementation and preserves its full-length complex output.

[`workload.json`](workload.json) covers singleton and unequal signals, signed and zero-valued samples, power-of-two padding, maximum counts, malformed packing and sample bounds, and insufficient output capacity. The independent mathematical oracle is [`convolution_fft_oracle.py`](../../convolution_fft_oracle.py).

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm convolution_fft --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/c/convolution_fft/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm convolution_fft
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/convolution_fft.c`](../../../c/c/convolution_fft.c) |
| C3 | [`c3/convolution_fft.c3`](../../../c3/c/convolution_fft.c3) |
| C++ | [`cpp/convolution_fft.cpp`](../../../cpp/c/convolution_fft.cpp) |
| Elisa | [`elisa/convolution_fft.elisa`](../../../elisa/c/convolution_fft.elisa) |
| Nim | [`nim/convolution_fft.nim`](../../../nim/c/convolution_fft.nim) |
| Odin | [`odin/convolution_fft.odin`](../../../odin/c/convolution_fft.odin) |
| Rust | [`rust/convolution_fft.rs`](../../../rust/c/convolution_fft.rs) |
| V | [`v/convolution_fft.v`](../../../v/c/convolution_fft.v) |
| Zig | [`zig/convolution_fft.zig`](../../../zig/c/convolution_fft.zig) |
