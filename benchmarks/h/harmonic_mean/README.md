# Harmonic mean

Compute the harmonic mean of a nonempty list of positive values, following the pinned Java `Means.harmonic` method.

## Contract

- The `i64_array_float64` ABI receives the values directly, with length 1 through 64.
- Each value is a positive integer from 1 through 1,000. Zero and negative values are excluded because the source formula sums reciprocals.
- Return `n / sum(1 / value)` as binary64, using relative and absolute tolerance `1e-12`.
- Empty input or out-of-range values return `-1e300`.
- The method takes `O(n)` time and constant auxiliary storage.

## Source

This follows the `harmonic` method in the pinned [TheAlgorithms Java `Means.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Means.java). The source divides the list length by the sum of each reciprocal. The benchmark uses a bounded positive integer subset and maps the source's empty-list exception to the sentinel.

## Workload

[`workload.json`](workload.json) covers singleton, equal values, the source example, reciprocal sums, the upper value and length bounds, and invalid input.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/harmonic_mean.c`](../../../c/h/harmonic_mean.c) |
| C3 | [`c3/h/harmonic_mean.c3`](../../../c3/h/harmonic_mean.c3) |
| C++ | [`cpp/h/harmonic_mean.cpp`](../../../cpp/h/harmonic_mean.cpp) |
| Elisa | [`elisa/h/harmonic_mean.elisa`](../../../elisa/h/harmonic_mean.elisa) |
| Nim | [`nim/h/harmonic_mean.nim`](../../../nim/h/harmonic_mean.nim) |
| Odin | [`odin/h/harmonic_mean.odin`](../../../odin/h/harmonic_mean.odin) |
| Rust | [`rust/h/harmonic_mean.rs`](../../../rust/h/harmonic_mean.rs) |
| V | [`v/h/harmonic_mean.v`](../../../v/h/harmonic_mean.v) |
| Zig | [`zig/h/harmonic_mean.zig`](../../../zig/h/harmonic_mean.zig) |

All ports use portable scalar operations and the shared `i64_array_float64` ABI.
