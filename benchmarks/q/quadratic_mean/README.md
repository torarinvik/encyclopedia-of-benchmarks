# Quadratic mean

Compute the quadratic mean, also called the root mean square, of a nonempty integer list.

## Contract

- The `i64_array_float64` ABI receives the values directly, with length 1 through 64.
- Each value is a signed integer in `[-1,000, 1,000]`.
- Return `sqrt(sum(value * value) / length)` as binary64, using relative and absolute tolerance `1e-12`.
- Empty input or out-of-range values return `-1e300`.
- The method takes `O(n)` time and constant auxiliary storage.

## Source

This follows the `quadratic` method in pinned [TheAlgorithms Java `Means.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Means.java). The source sums the squares, divides by list length, and takes the square root. The benchmark maps its empty-list exception and malformed ABI inputs to a sentinel.

## Workload

[`workload.json`](workload.json) covers the source example, signed values, zero, singleton behavior, maximum bounds and length, and invalid input.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/q/quadratic_mean.c`](../../../c/q/quadratic_mean.c) |
| C3 | [`c3/q/quadratic_mean.c3`](../../../c3/q/quadratic_mean.c3) |
| C++ | [`cpp/q/quadratic_mean.cpp`](../../../cpp/q/quadratic_mean.cpp) |
| Elisa | [`elisa/q/quadratic_mean.elisa`](../../../elisa/q/quadratic_mean.elisa) |
| Nim | [`nim/q/quadratic_mean.nim`](../../../nim/q/quadratic_mean.nim) |
| Odin | [`odin/q/quadratic_mean.odin`](../../../odin/q/quadratic_mean.odin) |
| Rust | [`rust/q/quadratic_mean.rs`](../../../rust/q/quadratic_mean.rs) |
| V | [`v/q/quadratic_mean.v`](../../../v/q/quadratic_mean.v) |
| Zig | [`zig/q/quadratic_mean.zig`](../../../zig/q/quadratic_mean.zig) |

All ports use portable scalar operations and the shared `i64_array_float64` ABI.
