# EMA filter

Apply the Java audio `EMAFilter` to one bounded sample sequence and return the full filtered trace. Each call models a fresh filter instance: the first output is the first input sample, then each following output uses the EMA recurrence.

## Contract

- ABI: signed i64 array to byte output. Input is `[alpha_units, sample_count, sample_0, ..., sample_(n-1)]`.
- `alpha_units` is 1 through 1024 and means `alpha_units / 1024.0`, a bounded binary-exact subset of the Java source's `0 < alpha <= 1` values. `sample_count` is 0 through 4 (at most six i64 slots for valid input). Samples are integers in `[-1,000,000, 1,000,000]`.
- The first output equals the first sample. For later samples, compute `alpha * current + (1 - alpha) * previous_output`, preserving the source expression order. A zero-sample input returns an empty byte array.
- The output contains one little-endian IEEE-754 binary64 value per sample, with no terminator. Invalid inputs return `-1`; insufficient output capacity returns `-2` without writing.
- The largest valid stream has four samples, so the source recurrence runs at most three updates. With `alpha = k / 2^10`, output denominators are at most `2^30`; bounded samples give numerator magnitude at most `1,000,000 * 2^30 < 2^50`. The ordered products and sum therefore fit within binary64’s 53-bit significand, making byte-for-byte output portable across the nine implementations.

## Source and workload

This is distinct from the repository's batch EMA and streaming mean/variance benchmarks. It follows [TheAlgorithms/Java `EMAFilter.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/audiofilters/EMAFilter.java). The source rejects alpha values outside `(0, 1]`; `apply(null)` and `apply(empty)` return an empty array, while each nonempty call resets the filter to the first sample and returns the full output sequence. This benchmark maps empty input to a zero sample count and limits samples to signed integers for a portable ABI.

[`workload.json`](workload.json) covers empty and single-sample signals, multiple alpha settings, first-sample seeding, recurrence updates, sample bounds, malformed lengths and values, and insufficient output capacity.

Build and record Rust with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm ema_filter --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/e/ema_filter/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm ema_filter --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/ema_filter.c`](../../../c/e/ema_filter.c) |
| C3 | [`c3/e/ema_filter.c3`](../../../c3/e/ema_filter.c3) |
| C++ | [`cpp/e/ema_filter.cpp`](../../../cpp/e/ema_filter.cpp) |
| Elisa | [`elisa/e/ema_filter.elisa`](../../../elisa/e/ema_filter.elisa) |
| Nim | [`nim/e/ema_filter.nim`](../../../nim/e/ema_filter.nim) |
| Odin | [`odin/e/ema_filter.odin`](../../../odin/e/ema_filter.odin) |
| Rust | [`rust/e/ema_filter.rs`](../../../rust/e/ema_filter.rs) |
| V | [`v/e/ema_filter.v`](../../../v/e/ema_filter.v) |
| Zig | [`zig/e/ema_filter.zig`](../../../zig/e/ema_filter.zig) |
