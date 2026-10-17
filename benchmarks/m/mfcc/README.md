# Mel-Frequency Cepstral Coefficients

This benchmark implements the bounded one-dimensional MFCC routine from [TheAlgorithms/Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/mfcc.py).

## Contract

The `i64_array_bytes_output_call` input is `[sample_count, sample_rate_hz, hop_length_ms, fft_size, mel_filter_count, dct_filter_count, sample_bits...]`. Each sample is an IEEE-754 binary64 bit pattern transported through a signed i64. There are 33–2048 finite samples with absolute value at most 1,000,000 and nonzero peak; sample rate is 8,000–48,000 Hz; hop is 1–50 ms; FFT size is 64, 128, 256, 512, or 1024; mel filters are 2–16; and DCT filters are 1–40. The rounded hop must be positive, reflect padding must be valid, and all filter-bin points must increase strictly. Inputs for which any frame/filter energy is nonpositive are invalid, preserving the source's un-floored `log10` behavior while keeping successful output finite.

The routine normalizes by peak absolute value, reflect-pads by half an FFT, frames at the hop rounded to an integer with ties-to-even, applies a periodic Hann window, and performs a forward FFT. FFT storage is rounded to complex64 and magnitude-square power to float32 before mel projection. Mel filters span 0 to `sample_rate_hz // 2`, use the source's mel conversion and floored bins, triangular `linspace` weights, and area normalization. The source's orthonormal DCT-II basis is applied to `10*log10` filter energies.

Successful output uses the shared variable-length bytes-output vector protocol: a flat row-major matrix of little-endian binary64 values, with `dct_filter_count` rows and `floor(sample_count / hop_size) + 1` columns. Shape is recorded per workload case. Maximum output is 82,240 bytes (257 frames × 40 coefficients). The output buffer is unchanged for invalid inputs and insufficient capacity; those return `-1` and `-2`, respectively.

## Workload and oracle

[`workload.json`](workload.json) covers parameter boundaries, reflect padding, scaling, invalid peaks/geometry/parameters, maximum output size, and output capacity. The independent [`mfcc_oracle.py`](../../mfcc_oracle.py) defines the expected outputs. Comparisons use absolute and relative tolerances of `1e-5` for every binary64 element.

## Language ports

- C: [`c/m/mfcc.c`](../../../c/m/mfcc.c)
- C3: [`c3/m/mfcc.c3`](../../../c3/m/mfcc.c3)
- C++: [`cpp/m/mfcc.cpp`](../../../cpp/m/mfcc.cpp)
- Elisa: [`elisa/m/mfcc.elisa`](../../../elisa/m/mfcc.elisa)
- Nim: [`nim/m/mfcc.nim`](../../../nim/m/mfcc.nim)
- Odin: [`odin/m/mfcc.odin`](../../../odin/m/mfcc.odin)
- Rust: [`rust/m/mfcc.rs`](../../../rust/m/mfcc.rs)
- V: [`v/m/mfcc.v`](../../../v/m/mfcc.v)
- Zig: [`zig/m/mfcc.zig`](../../../zig/m/mfcc.zig)
