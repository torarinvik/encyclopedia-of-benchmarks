# Poisson distribution helpers

This package benchmarks the deterministic rate, expected-count, point-probability, and inclusive-range functions from the pinned C++ Poisson distribution source.

## Contract

- The `i64_array_float64` input is `[operation, first_milli, second_milli, third]` and must contain exactly four integers.
- Operation `0` returns `poisson_rate(events, timeframe)`: `first_milli` is events multiplied by 1,000 and `second_milli` is timeframe multiplied by 1,000. Events may be 0–100, and timeframe must be 0.001–100.
- Operation `1` returns `poisson_expected(rate, time)`: `first_milli` is rate multiplied by 1,000 and `second_milli` is time multiplied by 1,000. Both inputs may be 0–100.
- Operation `2` returns `poisson_x_successes(expected, k)`: `first_milli` is the expected count multiplied by 1,000 (0–100), and `second_milli` is the integer success count `k` (0–20). `third` must be zero.
- Operation `3` returns `poisson_range_successes(expected, lower, upper)`: `first_milli` is the expected count multiplied by 1,000 (0–100); `second_milli` and `third` are inclusive integer bounds satisfying `0 <= lower <= upper <= 20`.
- Every unused field must be zero. Invalid shapes, selectors, or values return `-1e300`.
- The source's `fact(0)` fallback is 1, so the point probability for zero successes is `exp(-expected)`, including `expected == 0`.
- Results use relative tolerance `1e-12` and absolute tolerance `0`, preserving small nonzero probabilities such as the bounded mean-0.001, 20-success case.

The mean and success-count bounds keep the source's `pow`, factorial, and inclusive summation finite. Fixed-point inputs let each language receive the same decimal values through the integer-array ABI.

## Workload and source

[`workload.json`](workload.json) includes all four operations, the source's examples, zero and fractional values, bounded extremes, and malformed/domain-invalid inputs. The independent oracle is [`poisson_dist_oracle.py`](../../poisson_dist_oracle.py).

- [TheAlgorithms/C-Plus-Plus `probability/poisson_dist.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/probability/poisson_dist.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `probability/poisson_dist.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/probability/poisson_dist.cpp)

Both pinned files are identical. The operation selector exposes the four deterministic helpers while keeping each timed call to one scalar output.

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/p/poisson_dist.c`](../../../c/p/poisson_dist.c) |
| C3 | [`c3/p/poisson_dist.c3`](../../../c3/p/poisson_dist.c3) |
| C++ | [`cpp/p/poisson_dist.cpp`](../../../cpp/p/poisson_dist.cpp) |
| Elisa | [`elisa/p/poisson_dist.elisa`](../../../elisa/p/poisson_dist.elisa) |
| Nim | [`nim/p/poisson_dist.nim`](../../../nim/p/poisson_dist.nim) |
| Odin | [`odin/p/poisson_dist.odin`](../../../odin/p/poisson_dist.odin) |
| Rust | [`rust/p/poisson_dist.rs`](../../../rust/p/poisson_dist.rs) |
| V | [`v/p/poisson_dist.v`](../../../v/p/poisson_dist.v) |
| Zig | [`zig/p/poisson_dist.zig`](../../../zig/p/poisson_dist.zig) |
