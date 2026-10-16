# YIN pitch detection

Estimate a signal's fundamental frequency with the pinned Rust implementation of YIN. The benchmark returns its parabolically interpolated frequency estimate.

## Contract

The `i64_array_float64` input is `[count, sample_rate_hz, min_expected_hz, max_expected_hz, threshold_micro, sample_0, ...]`. It accepts 2 through 256 signed PCM-like samples in `[-32768, 32767]`, sample rates from 1 through 192,000 Hz, integer expected-frequency bounds with `1 <= min < max <= sample_rate/2`, and thresholds from 1 through 999,999 millionths. Samples are converted directly to binary64; scaling does not affect YIN's normalized difference values.

The source derives `min_lag=floor(sample_rate/max_expected_hz)` and `max_lag=floor(sample_rate/min_expected_hz)`. The benchmark requires `1 <= min_lag <= max_lag <= min(64, count-1)`. It calculates squared differences and CMNDF in ascending lag order, finds the first lag below the threshold, walks downhill while the next CMNDF value decreases, and applies the source's clipped-neighbor parabolic interpolation. It returns frequency in Hz. Invalid parameters or no qualifying lag return `-1e300`.

## Source

Follows the pinned Rust [`yin.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/signal_analysis/yin.rs). The repository's scalar and full-signal autocorrelation benchmarks compute different quantities.

## Workload

[`workload.json`](workload.json) includes quantized tones, a periodic waveform, silence, a no-threshold case, and malformed input.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/y/yin.c`](../../../c/y/yin.c) |
| C3 | [`c3/y/yin.c3`](../../../c3/y/yin.c3) |
| C++ | [`cpp/y/yin.cpp`](../../../cpp/y/yin.cpp) |
| Elisa | [`elisa/y/yin.elisa`](../../../elisa/y/yin.elisa) |
| Nim | [`nim/y/yin.nim`](../../../nim/y/yin.nim) |
| Odin | [`odin/y/yin.odin`](../../../odin/y/yin.odin) |
| Rust | [`rust/y/yin.rs`](../../../rust/y/yin.rs) |
| V | [`v/y/yin.v`](../../../v/y/yin.v) |
| Zig | [`zig/y/yin.zig`](../../../zig/y/yin.zig) |

Numerical comparison uses absolute tolerance `1e-9` and relative tolerance `1e-12`.
