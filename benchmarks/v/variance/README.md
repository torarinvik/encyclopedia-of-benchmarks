# Variance

Compute the unbiased sample variance of a bounded integer array. This package follows the pinned Julia `variance(a)` function: calculate the mean, sum squared deviations in input order, and divide by `n - 1`.

## Contract

- The `i64_array_float64_call` ABI receives the integer array and its length separately. Accept 2 through 64 values, each in `[-1,000,000, 1,000,000]`.
- First compute `avg = sum(values) / n`. Then, in input order, accumulate `(value - avg)²` and divide by `n - 1`. Return the result as binary64.
- Null input, invalid length, or out-of-range value returns `-1e300`. The bounds keep the sums finite and make all integer inputs exact as binary64 values. Compare results with absolute and relative tolerance `1e-12`.
- Runtime is O(n) with O(1) auxiliary space.

## Source semantics

The implementation follows [TheAlgorithms/Julia `variance.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/statistics/variance.jl) at commit `384424b762bbb40d43f31001beeca0c6ffda2f1f`. Its two-pass calculation uses the sample denominator `length(a) - 1`; length one is excluded because that denominator is zero.

The catalog also finds [TheAlgorithms/C `variance.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/numerical_methods/variance.c) at commit `e5dad3fa8def3726ec850ca66a7f51521f8ad393`. That file is an interactive program that creates random values and reports population variance using denominator `n`; it is not the same deterministic array function. The existing [`standard_deviation`](../standard_deviation/README.md) benchmark returns the square root of population variance, so its result also differs from this sample-variance contract.

## Workload

[`workload.json`](workload.json) includes constant, integer-mean, fractional-mean, negative, and maximum-magnitude samples, along with invalid length and element cases. Expected values use the pinned two-pass formula.

Build and record with the `i64_array_float64` family:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm variance --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/v/variance/rust/build.json
python3 benchmarks/verify_i64_array_float64.py --algorithm variance
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/v/variance.c`](../../../c/v/variance.c) |
| C3 | [`c3/v/variance.c3`](../../../c3/v/variance.c3) |
| C++ | [`cpp/v/variance.cpp`](../../../cpp/v/variance.cpp) |
| Elisa | [`elisa/v/variance.elisa`](../../../elisa/v/variance.elisa) |
| Nim | [`nim/v/variance.nim`](../../../nim/v/variance.nim) |
| Odin | [`odin/v/variance.odin`](../../../odin/v/variance.odin) |
| Rust | [`rust/v/variance.rs`](../../../rust/v/variance.rs) |
| V | [`v/v/variance.v`](../../../v/v/variance.v) |
| Zig | [`zig/v/variance.zig`](../../../zig/v/variance.zig) |
