# One-Way ANOVA

This package benchmarks the pinned [TheAlgorithms/R implementation](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/regression_algorithms/anova_oneway.r). It computes the classic one-way analysis-of-variance statistics from integer observations and group labels.

The `i64_array_float64` ABI input is `[statistic, n, k, x_0..x_(n-1), g_0..g_(n-1)]`. The selector `statistic` chooses, in order: between-groups degrees of freedom, within-groups degrees of freedom, between-groups sum of squares, within-groups sum of squares, between-groups mean square, within-groups mean square, F statistic, or right-tail p-value. The input is limited to 3–128 observations, 2–8 contiguous group labels, `n > k`, and observations in `[-1,000,000, 1,000,000]`; each group must occur. Cases with zero within-groups sum of squares are excluded because the source's F statistic and p-value are non-finite there. Malformed or out-of-domain inputs return `-1e300`.

For the p-value, the ports use the F survival-function identity expressed as a regularized incomplete beta function. They use portable scalar floating-point and standard logarithm/exponential operations, with no processor-specific instructions. Outputs are binary64 and compared with absolute and relative tolerance `1e-12`.

Runtime is O(nk) for the sums of squares and bounded by 200 continued-fraction iterations for the p-value; auxiliary space is O(n + k).

| Language | Implementation |
| --- | --- |
| C | [`c/a/anova_oneway.c`](../../../c/a/anova_oneway.c) |
| C3 | [`c3/a/anova_oneway.c3`](../../../c3/a/anova_oneway.c3) |
| C++ | [`cpp/a/anova_oneway.cpp`](../../../cpp/a/anova_oneway.cpp) |
| Elisa | [`elisa/a/anova_oneway.elisa`](../../../elisa/a/anova_oneway.elisa) |
| Nim | [`nim/a/anova_oneway.nim`](../../../nim/a/anova_oneway.nim) |
| Odin | [`odin/a/anova_oneway.odin`](../../../odin/a/anova_oneway.odin) |
| Rust | [`rust/a/anova_oneway.rs`](../../../rust/a/anova_oneway.rs) |
| V | [`v/a/anova_oneway.v`](../../../v/a/anova_oneway.v) |
| Zig | [`zig/a/anova_oneway.zig`](../../../zig/a/anova_oneway.zig) |
