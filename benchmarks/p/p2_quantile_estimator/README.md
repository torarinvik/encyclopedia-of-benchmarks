# P² quantile estimator

The pinned Java `P2QuantileEstimator` stores the first five samples, then initializes five sorted markers and updates them with desired positions, parabolic prediction, and linear fallback. For fewer than five samples its quantile is exact linear interpolation at rank `p * (n - 1)`.

## Contract

This benchmark fixes the estimator probability to `p=0.5` (median). Input is `[sample_count, signed_i32_samples...]`, with 1–64 samples. Output is binary64: for fewer than five samples it is the exact interpolated median; from five onward it is the center P² marker. Malformed input returns `-1e300`.

The benchmark follows the Java order of arithmetic in the parabolic prediction because its strict height comparisons can choose between parabolic and linear updates. See [`workload.json`](workload.json), the runtime [oracle](../../p2_quantile_estimator_oracle.py), and the [pinned Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/P2QuantileEstimator.java).

| Language | Port |
|---|---|
| C | [`c/p/p2_quantile_estimator.c`](../../../c/p/p2_quantile_estimator.c) |
| C3 | [`c3/p/p2_quantile_estimator.c3`](../../../c3/p/p2_quantile_estimator.c3) |
| C++ | [`cpp/p/p2_quantile_estimator.cpp`](../../../cpp/p/p2_quantile_estimator.cpp) |
| Elisa | [`elisa/p/p2_quantile_estimator.elisa`](../../../elisa/p/p2_quantile_estimator.elisa) |
| Nim | [`nim/p/p2_quantile_estimator.nim`](../../../nim/p/p2_quantile_estimator.nim) |
| Odin | [`odin/p/p2_quantile_estimator.odin`](../../../odin/p/p2_quantile_estimator.odin) |
| Rust | [`rust/p/p2_quantile_estimator.rs`](../../../rust/p/p2_quantile_estimator.rs) |
| V | [`v/p/p2_quantile_estimator.v`](../../../v/p/p2_quantile_estimator.v) |
| Zig | [`zig/p/p2_quantile_estimator.zig`](../../../zig/p/p2_quantile_estimator.zig) |
