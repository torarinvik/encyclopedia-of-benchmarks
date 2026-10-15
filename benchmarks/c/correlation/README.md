# Discrete Correlation (Pinned Java Behavior)

This benchmark follows the pinned Java implementation over two equally sized discrete variables. Its actual calculation is kept as written, including a nonstandard denominator that differs from the usual Pearson coefficient.

## Contract

- The `i64_array_float64` ABI packs `[n, x[0], ..., x[n-1], y[0], ..., y[n-1]]` as signed 64-bit integers. Require `1 <= n <= 128`, exact length `1 + 2*n`, and samples in `[-1000, 1000]`.
- In source order, accumulate `E[XY]`, `E[X]`, `E[X²]`, `E[Y]`, and `E[Y²]`; divide each sum by `n`; compute `cov = E[XY] - E[X]*E[Y]`, `varx = sqrt(E[X²] - E[X]²)`, and `vary = sqrt(E[Y²] - E[Y]²)`.
- The source then returns zero when `varx*vary < 1e-9`; otherwise it returns `cov / sqrt(varx*vary)`. Here `varx` and `vary` already contain square roots, so this is not the standard Pearson normalization. Results can exceed `[-1,1]`; ports preserve the Java expression rather than replacing it with standard Pearson correlation.
- Malformed inputs or values outside the contract return `-1e300`. Results use relative and absolute tolerance `1e-12`.

This candidate is distinct from the standard Pearson calculation and from `linear_regression_ols`, which returns a regression slope. The source documents constant-variable correlation as zero; the benchmark includes n=1, where that branch also returns zero.

## Source

- [TheAlgorithms/Java `Correlation.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Correlation.java)
- Related but semantically different: [TheAlgorithms/Julia `pearson_correlation.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/statistics/pearson_correlation.jl) uses standard Pearson normalization.

## Workload and build

[`workload.json`](workload.json) covers a single sample, constant variables, positive and negative association, and a result above one that exposes the source normalization. Build with the `i64_array_float64` ABI and record with `benchmarks/run_i64_array_float64.py`.

The shared runner validates the workload by preserving the source's ordered sums and its nonstandard final normalization.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm correlation --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/c/correlation/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/c/correlation.c`](../../../c/correlation.c) |
| C3 | [`c3/c/correlation.c3`](../../../c3/correlation.c3) |
| C++ | [`cpp/c/correlation.cpp`](../../../cpp/correlation.cpp) |
| Elisa | [`elisa/c/correlation.elisa`](../../../elisa/c/correlation.elisa) |
| Nim | [`nim/c/correlation.nim`](../../../nim/c/correlation.nim) |
| Odin | [`odin/c/correlation.odin`](../../../odin/c/correlation.odin) |
| Rust | [`rust/c/correlation.rs`](../../../rust/c/correlation.rs) |
| V | [`v/c/correlation.v`](../../../v/c/correlation.v) |
| Zig | [`zig/c/correlation.zig`](../../../zig/c/correlation.zig) |
