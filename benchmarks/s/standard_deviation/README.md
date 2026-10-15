# Standard deviation

Compute the population standard deviation of a nonempty array of bounded signed integers, returning a binary64 value. The contract follows the two-pass algorithm in the pinned Java `StandardDeviation.stdDev`: average the values in input order, then sum squared deviations in input order, divide by the population size, and take the square root.

## Contract

- Input is an array of 1 to 64 signed 64-bit integers, each in `[-1,000,000, 1,000,000]`.
- The first pass adds values in input order and computes `average = sum / n` as binary64. The second pass adds `pow(value - average, 2)` in input order, divides by `n`, and returns the square root. The denominator is the population size `n`, not `n - 1`.
- Invalid input returns `-1e300`. The benchmark excludes empty input because the pinned source computes NaN for an empty array, while the runner accepts only finite expected results.
- The bounds keep every sum and squared-deviation total finite and far below the binary64 exact-integer limit. The method uses `O(n)` time and `O(1)` auxiliary space.

## Source and related algorithms

The pinned [Java `StandardDeviation.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/StandardDeviation.java) computes population standard deviation with two passes and has no explicit input validation. A one-element input returns positive zero. Its empty-input result is NaN from division by zero. This package measures the standard deviation result; the separate `variance` candidate returns variance and is not interchangeable.

## Workload and build

[`workload.json`](workload.json) covers zero spread, a singleton, integer and fractional means, negative values, and invalid bounds. All nine ports use the shared `i64_array_float64` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm standard_deviation --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/s/standard_deviation/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/s/standard_deviation.c`](../../../c/s/standard_deviation.c) |
| C3 | [`c3/s/standard_deviation.c3`](../../../c3/s/standard_deviation.c3) |
| C++ | [`cpp/s/standard_deviation.cpp`](../../../cpp/s/standard_deviation.cpp) |
| Elisa | [`elisa/s/standard_deviation.elisa`](../../../elisa/s/standard_deviation.elisa) |
| Nim | [`nim/s/standard_deviation.nim`](../../../nim/s/standard_deviation.nim) |
| Odin | [`odin/s/standard_deviation.odin`](../../../odin/s/standard_deviation.odin) |
| Rust | [`rust/s/standard_deviation.rs`](../../../rust/s/standard_deviation.rs) |
| V | [`v/s/standard_deviation.v`](../../../v/s/standard_deviation.v) |
| Zig | [`zig/s/standard_deviation.zig`](../../../zig/s/standard_deviation.zig) |
