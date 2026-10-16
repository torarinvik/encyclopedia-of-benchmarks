# Complementary filter

Run the Java complementary filter over a bounded sequence of gyroscope rates, reference readings, and elapsed times, returning the final estimate.

## Contract

- The i64_array_float64 ABI receives `[coefficient_ppm, sample_count, rate_1_micro, reference_1_micro, elapsed_1_micro, ...]` with exactly three integer values per sample.
- `coefficient_ppm` is in `[1, 999999]` and decodes as `coefficient_ppm / 1,000,000.0`, preserving the Java constructor's open interval `(0, 1)`. `sample_count` is in `[1, 32]`.
- Each rate and reference is in `[-1,000,000, 1,000,000]` and decodes in units of `1e-6`. Each elapsed time is in `[1, 1,000,000]` and decodes in seconds as `elapsed_micro / 1,000,000.0`. This finite integer grid satisfies the source's finite-reading and positive-time guards.
- A fresh filter starts with count zero. Its first `accept` call sets the estimate to the reference. Later calls preserve the source expression order: `coefficient * (value + rate * elapsed) + (1.0 - coefficient) * reference`.
- The benchmark returns the final estimate after all samples. Malformed arrays or out-of-contract values return `-1e300`. Results use relative and absolute tolerance `1e-12`.
- Time is `O(sample_count)` and extra state is `O(1)`.

## Source

This follows the pinned [TheAlgorithms/Java ComplementaryFilter.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/ComplementaryFilter.java). It models `scan` as successive calls to `accept` on a fresh filter and returns the last estimate so the existing scalar-result ABI can represent the workload.

## Workload and build

[`workload.json`](workload.json) covers the first-sample seed, the default coefficient, multiple updates, coefficient extremes, varied elapsed times, the maximum sequence, and invalid shapes and ranges. The source-backed expected-value check belongs in the shared i64_array_float64 runner.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm complementary_filter --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/c/complementary_filter/rust/build.json
```

## Verification

Run the independent stateful-filter oracle against the supported language ports with:

```sh
python3 benchmarks/verify_complementary_filter.py
```

## Ports

| Language | Source |
| --- | --- |
| C | [c/c/complementary_filter.c](../../../c/c/complementary_filter.c) |
| C3 | [c3/c/complementary_filter.c3](../../../c3/c/complementary_filter.c3) |
| C++ | [cpp/c/complementary_filter.cpp](../../../cpp/c/complementary_filter.cpp) |
| Elisa | [elisa/c/complementary_filter.elisa](../../../elisa/c/complementary_filter.elisa) |
| Nim | [nim/c/complementary_filter.nim](../../../nim/c/complementary_filter.nim) |
| Odin | [odin/c/complementary_filter.odin](../../../odin/c/complementary_filter.odin) |
| Rust | [rust/c/complementary_filter.rs](../../../rust/c/complementary_filter.rs) |
| V | [v/c/complementary_filter.v](../../../v/c/complementary_filter.v) |
| Zig | [zig/c/complementary_filter.zig](../../../zig/c/complementary_filter.zig) |
