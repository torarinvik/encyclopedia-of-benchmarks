# Standard score

## Contract

Given `[value, mean, stdDev]`, return the standard score using the pinned operation order:

`(value - mean) / stdDev`

All inputs are finite binary64 values. `value` and `mean` are in `[-1,000,000, 1,000,000]`; `stdDev` is nonzero and lies in `[-1,000,000, -0.000001]` or `[0.000001, 1,000,000]`. Negative nonzero standard deviations remain in the domain because the source divides without a positivity check. The bounds keep every result finite. Inputs outside this contract return `-1e300`.

The exported function is `double standard_score(double value, double mean, double std_dev)`. It uses the shared `float64_triple` ABI. This is the direct z-score calculation; it does not estimate the mean or standard deviation from a sample.

## Source review

The pinned Java source implements `zScore(num, mean, stdDev)` as exactly `(num - mean) / stdDev`, with no validation or intermediate rounding. The benchmark keeps that subtraction-then-division order and defines a bounded portable input domain around it. There is no existing standard-score or z-score benchmark package in this checkout.

## Workload and recording

[`workload.json`](workload.json) covers the source formula, positive and negative scores, both signs of `stdDev`, zero output, and the finite domain boundaries. Results are compared with a scaled binary64 tolerance of `1e-12`.

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm standard_score --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/s/standard_score/rust/build.json
python3 benchmarks/verify_float64_triple.py --algorithm standard_score
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/standard_score.c`](../../../c/s/standard_score.c) |
| C3 | [`c3/s/standard_score.c3`](../../../c3/s/standard_score.c3) |
| C++ | [`cpp/s/standard_score.cpp`](../../../cpp/s/standard_score.cpp) |
| Elisa | [`elisa/s/standard_score.elisa`](../../../elisa/s/standard_score.elisa) |
| Nim | [`nim/s/standard_score.nim`](../../../nim/s/standard_score.nim) |
| Odin | [`odin/s/standard_score.odin`](../../../odin/s/standard_score.odin) |
| Rust | [`rust/s/standard_score.rs`](../../../rust/s/standard_score.rs) |
| V | [`v/s/standard_score.v`](../../../v/s/standard_score.v) |
| Zig | [`zig/s/standard_score.zig`](../../../zig/s/standard_score.zig) |

## TheAlgorithms reference

- Java [`StandardScore.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/StandardScore.java)
