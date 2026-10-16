# One-Dimensional Convolution

This benchmark ports TheAlgorithms/Python's `DiscreteConvolve1D.convolve_1d` property. For signal length `n` and kernel length `m`, the output has exactly `n` values. At output index `i`, it accumulates `kernel[j] * signal[i + j - floor(m / 2)]` in increasing `j` order, treating signal indices outside `[0, n)` as zero. The kernel is used in its input order and is not reversed.

## Contract

- The `i64_array_bytes_output` input is `[signal_length, kernel_length, signal_fixed..., kernel_fixed...]`. Both lengths range from 0 through 64, and the packed length must be exactly `2 + signal_length + kernel_length`.
- Each sample is a signed integer `q` in `[-128, 128]`, interpreted as the exact binary64 value `q / 16`. This bounded dyadic grid represents integer and fractional source samples while keeping cross-language output exact.
- Output is a little-endian IEEE-754 binary64 vector with one value per signal sample. The successful result is its byte length; an empty signal returns 0 with no bytes. Invalid inputs return -1. A valid input with an unavailable or undersized output buffer returns -2 when output bytes are required.
- The source `Signal` defaults its public count to the number of stored samples, and the convolution increments its result count once per output index. The benchmark keeps that default behavior, so the result count equals the output vector length.

## Pinned source

- Python [`convolve_1d.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/convolve_1d.py)

## Workload and build

[`workload.json`](workload.json) covers centered odd and even kernels, zero-padding, empty signal/kernel boundaries, malformed packed inputs, sample bounds, and insufficient output capacity. The independent oracle is [`convolve_1d_oracle.py`](../../convolve_1d_oracle.py).

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm convolve_1d --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/c/convolve_1d/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm convolve_1d
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/convolve_1d.c`](../../../c/c/convolve_1d.c) |
| C3 | [`c3/convolve_1d.c3`](../../../c3/c/convolve_1d.c3) |
| C++ | [`cpp/convolve_1d.cpp`](../../../cpp/c/convolve_1d.cpp) |
| Elisa | [`elisa/convolve_1d.elisa`](../../../elisa/c/convolve_1d.elisa) |
| Nim | [`nim/convolve_1d.nim`](../../../nim/c/convolve_1d.nim) |
| Odin | [`odin/convolve_1d.odin`](../../../odin/c/convolve_1d.odin) |
| Rust | [`rust/convolve_1d.rs`](../../../rust/c/convolve_1d.rs) |
| V | [`v/convolve_1d.v`](../../../v/c/convolve_1d.v) |
| Zig | [`zig/convolve_1d.zig`](../../../zig/c/convolve_1d.zig) |
