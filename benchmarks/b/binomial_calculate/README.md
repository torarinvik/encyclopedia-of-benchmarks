# Binomial coefficient

Compute `n choose k` using the iterative multiplicative recurrence from the pinned C++ sources.

## Contract

The `i64_array_scalar` input is exactly `[n, k]`, with `0 <= k <= n <= 62`. The result is the exact binomial coefficient as a signed 64-bit integer; malformed or out-of-domain input returns `-1`.

The implementation first replaces `k` with `min(k, n-k)`, then multiplies by `n-k+i` and divides by `i` for each `i` from 1 through `k`. The `n <= 62` bound keeps the pinned `size_t` intermediate multiplication within unsigned 64-bit range and the final coefficient within signed 64-bit range.

## Workload

[`workload.json`](workload.json) includes the pinned examples through `n=62`, edge cases for `k=0` and `k=n`, symmetry, and malformed or out-of-domain inputs.
The shared scalar runner now checks this bounded multiplicative recurrence.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binomial_calculate.c`](../../../c/b/binomial_calculate.c) |
| C3 | [`c3/b/binomial_calculate.c3`](../../../c3/b/binomial_calculate.c3) |
| C++ | [`cpp/b/binomial_calculate.cpp`](../../../cpp/b/binomial_calculate.cpp) |
| Elisa | [`elisa/b/binomial_calculate.elisa`](../../../elisa/b/binomial_calculate.elisa) |
| Nim | [`nim/b/binomial_calculate.nim`](../../../nim/b/binomial_calculate.nim) |
| Odin | [`odin/b/binomial_calculate.odin`](../../../odin/b/binomial_calculate.odin) |
| Rust | [`rust/b/binomial_calculate.rs`](../../../rust/b/binomial_calculate.rs) |
| V | [`v/b/binomial_calculate.v`](../../../v/b/binomial_calculate.v) |
| Zig | [`zig/b/binomial_calculate.zig`](../../../zig/b/binomial_calculate.zig) |

## Pinned sources

- C++ [`binomial_calculate.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/binomial_calculate.cpp)
- C++-1 [`binomial_calculate.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/binomial_calculate.cpp)
