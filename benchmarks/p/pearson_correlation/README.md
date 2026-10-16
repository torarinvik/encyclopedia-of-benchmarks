# Pearson Correlation

Compute the standard Pearson product-moment correlation coefficient for two bounded integer samples.

## Contract

- Input is `[n, x[0..n), y[0..n)]`, with `2 <= n <= 128`, exact length `1 + 2*n`, and sample values in `[-1,000,000, 1,000,000]`.
- Compute each sample mean, then the centered cross-product sum and the two centered square sums. Return `sum(dx*dy) / sqrt(sum(dx*dx) * sum(dy*dy))` as binary64.
- Constant samples have an undefined Pearson coefficient and return the benchmark's `-1e300` invalid-result sentinel. Malformed layouts and out-of-range samples use the same sentinel.
- The bounded integer domain avoids overflow in every supported language. Results use absolute tolerance `1e-10` and relative tolerance `1e-12`.

## Source

- [TheAlgorithms/Julia `pearson_correlation.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/statistics/pearson_correlation.jl) computes the means, centered cross-products, and centered sums of squares directly.
- [TheAlgorithms/R `correlation_analysis.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/biomedical/correlation_analysis.r) contains the same standard coefficient as part of its Pearson analysis result. Its confidence intervals, hypothesis tests, assumption checks, and plotting are separate operations and are outside this scalar contract.
- This is distinct from [TheAlgorithms/Java `Correlation.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Correlation.java), whose nonstandard final normalization is preserved by the separate `correlation` benchmark.

## Workload and build

[`workload.json`](workload.json) includes the Julia documentation example, positive and negative perfect correlation, zero and fractional coefficients, the two-observation boundary, maximum input length, constant samples, and malformed data.

Build with the shared binary64 ABI and record the workload:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm pearson_correlation --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/p/pearson_correlation/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/p/pearson_correlation.c`](../../../c/p/pearson_correlation.c) |
| C3 | [`c3/p/pearson_correlation.c3`](../../../c3/p/pearson_correlation.c3) |
| C++ | [`cpp/p/pearson_correlation.cpp`](../../../cpp/p/pearson_correlation.cpp) |
| Elisa | [`elisa/p/pearson_correlation.elisa`](../../../elisa/p/pearson_correlation.elisa) |
| Nim | [`nim/p/pearson_correlation.nim`](../../../nim/p/pearson_correlation.nim) |
| Odin | [`odin/p/pearson_correlation.odin`](../../../odin/p/pearson_correlation.odin) |
| Rust | [`rust/p/pearson_correlation.rs`](../../../rust/p/pearson_correlation.rs) |
| V | [`v/p/pearson_correlation.v`](../../../v/p/pearson_correlation.v) |
| Zig | [`zig/p/pearson_correlation.zig`](../../../zig/p/pearson_correlation.zig) |
