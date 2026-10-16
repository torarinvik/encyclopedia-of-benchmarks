# Welford's variance

This benchmark ports the pinned C# `WelfordsVariance` online sample-variance update. Each sample updates the count, running mean, and sum of squared deviations in one pass.

## Contract

The `i64_array_float64` ABI accepts 2–64 signed 64-bit integer values, each in [-1,000,000, 1,000,000]. For each input `x`, update `count += 1`, `delta = x - mean`, `mean += delta / count`, then `M2 += delta * (x - mean)`. Return `M2 / (count - 1)` as binary64. Invalid length or values return `-1e300`. The benchmark narrows the source's double-valued API to bounded integers and excludes its NaN result for fewer than two samples.

This is a one-pass recurrence and remains separate from [`variance`](../variance/README.md), which computes the same statistic with a two-pass centered sum.

[`workload.json`](workload.json) covers constant and varied values, negative values, fractional means, maximum bounded magnitudes, and invalid lengths/ranges.

## Pinned source

- [C-Sharp `WelfordsVariance.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6/Algorithms/Other/WelfordsVariance.cs)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/w/welfords_variance.c`](../../../c/w/welfords_variance.c) |
| C3 | [`c3/w/welfords_variance.c3`](../../../c3/w/welfords_variance.c3) |
| C++ | [`cpp/w/welfords_variance.cpp`](../../../cpp/w/welfords_variance.cpp) |
| Elisa | [`elisa/w/welfords_variance.elisa`](../../../elisa/w/welfords_variance.elisa) |
| Nim | [`nim/w/welfords_variance.nim`](../../../nim/w/welfords_variance.nim) |
| Odin | [`odin/w/welfords_variance.odin`](../../../odin/w/welfords_variance.odin) |
| Rust | [`rust/w/welfords_variance.rs`](../../../rust/w/welfords_variance.rs) |
| V | [`v/w/welfords_variance.v`](../../../v/w/welfords_variance.v) |
| Zig | [`zig/w/welfords_variance.zig`](../../../zig/w/welfords_variance.zig) |
