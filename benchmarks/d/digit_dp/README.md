# Digit DP

Count integers in an inclusive range whose decimal digits sum to a requested target, following the pinned Java `DigitDP.countRangeWithDigitSum` method.

## Contract

- The `i64_array_scalar` input is `[lower, upper, target]`.
- `lower` and `upper` must be in `[-1, 10^18]`; `target` must fit a signed 32-bit integer. Valid inputs have exactly three values. A four-value malformed fixture is parseable so the exact-length guard is exercised.
- The Java method treats negative numbers as contributing zero. If `lower > upper`, `target < 0`, or `target > 171`, the result is 0, matching the source. Otherwise the result counts nonnegative integers in the range whose decimal digit sum equals `target`.
- Malformed length, out-of-range bounds, or a target outside signed 32-bit range returns `-1`. The largest possible count in this contract fits signed 64-bit output.
- The Java source uses top-down memoized digit DP. The ports use the equivalent bounded digit-DP state transitions; the oracle uses a separate memoized implementation.

## Pinned source

The benchmark maps to Java [`DigitDP.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/DigitDP.java), which counts values up to each bound and subtracts the count through `lower - 1` from the count through `upper`.

[`workload.json`](workload.json) covers the source example, zero and negative bounds, inclusive ranges, target boundaries, the maximum bound, and malformed packed inputs.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm digit_dp --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/d/digit_dp/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms digit_dp
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/digit_dp.c`](../../../c/d/digit_dp.c) |
| C3 | [`c3/d/digit_dp.c3`](../../../c3/d/digit_dp.c3) |
| C++ | [`cpp/d/digit_dp.cpp`](../../../cpp/d/digit_dp.cpp) |
| Elisa | [`elisa/d/digit_dp.elisa`](../../../elisa/d/digit_dp.elisa) |
| Nim | [`nim/d/digit_dp.nim`](../../../nim/d/digit_dp.nim) |
| Odin | [`odin/d/digit_dp.odin`](../../../odin/d/digit_dp.odin) |
| Rust | [`rust/d/digit_dp.rs`](../../../rust/d/digit_dp.rs) |
| V | [`v/d/digit_dp.v`](../../../v/d/digit_dp.v) |
| Zig | [`zig/d/digit_dp.zig`](../../../zig/d/digit_dp.zig) |
