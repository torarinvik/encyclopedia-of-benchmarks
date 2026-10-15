# Java streaming exponential moving average

This package ports the streaming `ExponentialMovingAverage` state update from the pinned Java source. It starts from an explicit seed and applies each sample immediately using `mean += alpha * (sample - mean_before)`. It also preserves the paired streaming variance update, which uses that same pre-update deviation.

## Contract

Use the `i64_array_bytes_output` ABI with input `[seed, sample_count, sample_0, ..., sample_(n-1)]`. The sample count is 0..256 and the seed and samples are signed integers in `[-1,000,000, 1,000,000]`. Alpha is fixed at exactly `0.25`. The seed initializes the mean; variance starts at zero; the seed is not included in the sample count.

The 24 output bytes contain little-endian binary64 final mean, little-endian binary64 final variance, and a little-endian signed i64 sample count. A zero-sample stream returns the seed, zero variance, and count zero. Malformed input returns `-1`; insufficient output capacity returns `-2` without writing.

[`workload.json`](workload.json) covers empty, rising, falling, constant, and alternating streams, bounds, malformed lengths, and output capacity.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm exponential_moving_average_java_stream --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/e/exponential_moving_average_java_stream/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/exponential_moving_average_java_stream.c`](../../../c/e/exponential_moving_average_java_stream.c) |
| C3 | [`c3/e/exponential_moving_average_java_stream.c3`](../../../c3/e/exponential_moving_average_java_stream.c3) |
| C++ | [`cpp/e/exponential_moving_average_java_stream.cpp`](../../../cpp/e/exponential_moving_average_java_stream.cpp) |
| Elisa | [`elisa/e/exponential_moving_average_java_stream.elisa`](../../../elisa/e/exponential_moving_average_java_stream.elisa) |
| Nim | [`nim/e/exponential_moving_average_java_stream.nim`](../../../nim/e/exponential_moving_average_java_stream.nim) |
| Odin | [`odin/e/exponential_moving_average_java_stream.odin`](../../../odin/e/exponential_moving_average_java_stream.odin) |
| Rust | [`rust/e/exponential_moving_average_java_stream.rs`](../../../rust/e/exponential_moving_average_java_stream.rs) |
| V | [`v/e/exponential_moving_average_java_stream.v`](../../../v/e/exponential_moving_average_java_stream.v) |
| Zig | [`zig/e/exponential_moving_average_java_stream.zig`](../../../zig/e/exponential_moving_average_java_stream.zig) |

## Pinned source

- Java [`ExponentialMovingAverage.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/ExponentialMovingAverage.java)
