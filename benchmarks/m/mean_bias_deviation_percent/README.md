# Mean bias deviation percentage

Measure the signed mean prediction error relative to the mean of the actual
values, expressed as a percentage. This package isolates `mbd(predict, actual)`
from the other metrics in the pinned
[TheAlgorithms/Python `scoring_functions.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/scoring_functions.py)
at commit `e1a2a8b016001309a73d5fec4818c35cca139795`. It is distinct from the
absolute-error and squared-error benchmarks.

## Contract

The `i64_array_float64` input is
`[n, predict[0..n], actual[0..n]]`, with exactly `1 + 2*n` values. There are
1..64 paired samples, each an integer in `[-1000, 1000]`. The sum of actual
values must be nonzero. These bounds keep the source's NumPy integer sums
within signed 64-bit range and exactly representable as binary64.

The result follows the source expression order:

```text
numerator = sum(predict[i] - actual[i]) / n
denominator = sum(actual[i]) / n
score = numerator / denominator * 100
```

Return the score as binary64 with absolute and relative tolerances of `1e-12`.
Malformed input, empty arrays, out-of-range samples, or a zero actual mean
return the finite sentinel `-1e300`. The independent oracle is
[`benchmarks/mean_bias_deviation_percent_oracle.py`](../../mean_bias_deviation_percent_oracle.py).

[`workload.json`](workload.json) covers the source's overprediction and
underprediction examples, zero error, a negative actual mean, a single pair,
the maximum sample count, and malformed or undefined cases.

Build and record the Rust port with:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm mean_bias_deviation_percent --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/m/mean_bias_deviation_percent/rust/build.json
python3 benchmarks/verify_i64_array_float64.py --algorithm mean_bias_deviation_percent --languages rust
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/m/mean_bias_deviation_percent.c`](../../../c/m/mean_bias_deviation_percent.c) |
| C3 | [`c3/m/mean_bias_deviation_percent.c3`](../../../c3/m/mean_bias_deviation_percent.c3) |
| C++ | [`cpp/m/mean_bias_deviation_percent.cpp`](../../../cpp/m/mean_bias_deviation_percent.cpp) |
| Elisa | [`elisa/m/mean_bias_deviation_percent.elisa`](../../../elisa/m/mean_bias_deviation_percent.elisa) |
| Nim | [`nim/m/mean_bias_deviation_percent.nim`](../../../nim/m/mean_bias_deviation_percent.nim) |
| Odin | [`odin/m/mean_bias_deviation_percent.odin`](../../../odin/m/mean_bias_deviation_percent.odin) |
| Rust | [`rust/m/mean_bias_deviation_percent.rs`](../../../rust/m/mean_bias_deviation_percent.rs) |
| V | [`v/m/mean_bias_deviation_percent.v`](../../../v/m/mean_bias_deviation_percent.v) |
| Zig | [`zig/m/mean_bias_deviation_percent.zig`](../../../zig/m/mean_bias_deviation_percent.zig) |
