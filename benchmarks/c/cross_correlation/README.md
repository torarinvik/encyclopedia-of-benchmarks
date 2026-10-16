# Linear cross-correlation

This benchmark follows the pinned Java [`CrossCorrelation.crossCorrelation`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/CrossCorrelation.java). It computes the full linear overlap of two finite signals, moving the second signal from its final sample across the first signal through its initial sample. The result contains `x_count + y_count - 1` coefficients in that source-defined order; the second signal is effectively reversed as the overlap shifts.

## Contract

The `i64_array_bytes_output` ABI packs `[x_count, y_count, x0, ..., y0, ...]`. Each signal length is 1..32, the packed length must be exactly `2 + x_count + y_count`, and each integer sample is in `[-1,000,000, 1,000,000]`. For output index `i`, the implementation sums `x[k] * y[y_start + (k - k_min)]` over the source's overlapping index range, where `k_min = max(0, i - (y_count - 1))` and `k_max = min(i, x_count - 1)`.

The Java source returns binary64 coefficients. On this integer domain each coefficient is an exact integer with magnitude at most `32,000,000,000,000`, below the binary64 exact-integer limit. The benchmark writes each coefficient as a signed 64-bit integer in little-endian order. Success returns `8 * (x_count + y_count - 1)` bytes. Malformed inputs return `-1`; a null or undersized output buffer returns `-2`.

The workload covers the pinned example, unequal signal lengths, source overlap orientation, signed values, singleton and maximum sample cases, maximum lengths, invalid input bounds, and an undersized output buffer.

Verify the nine ports with `python3 benchmarks/verify_i64_array_bytes_output.py --algorithm cross_correlation`.

## Pinned source and ports

- Java [`CrossCorrelation.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/CrossCorrelation.java)

| Language | Source |
| --- | --- |
| C | [`c/c/cross_correlation.c`](../../../c/c/cross_correlation.c) |
| C3 | [`c3/c/cross_correlation.c3`](../../../c3/c/cross_correlation.c3) |
| C++ | [`cpp/c/cross_correlation.cpp`](../../../cpp/c/cross_correlation.cpp) |
| Elisa | [`elisa/c/cross_correlation.elisa`](../../../elisa/c/cross_correlation.elisa) |
| Nim | [`nim/c/cross_correlation.nim`](../../../nim/c/cross_correlation.nim) |
| Odin | [`odin/c/cross_correlation.odin`](../../../odin/c/cross_correlation.odin) |
| Rust | [`rust/c/cross_correlation.rs`](../../../rust/c/cross_correlation.rs) |
| V | [`v/c/cross_correlation.v`](../../../v/c/cross_correlation.v) |
| Zig | [`zig/c/cross_correlation.zig`](../../../zig/c/cross_correlation.zig) |
