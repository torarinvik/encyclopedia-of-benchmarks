# Naive trial-division prime check

This benchmark follows the unoptimized `TrialDivision` method in the pinned Go source. It checks divisors from 2 up to, but not including, the input and returns when it finds a factor.

## Contract

- Inputs below 2 return `0`; prime inputs from 2 through 10,000 return `1`; composites in that range return `0`.
- Inputs greater than 10,000 return `-1`. Negative signed 64-bit values are accepted and return `0`, as in the source.
- The bounded scalar call uses O(n) time and O(1) extra space. It remains separate from [`prime_check`](../prime_check/README.md), which skips even factors and stops at the square root.

The maximum input is limited to keep the linear search practical during measurement. The workload uses one call per sample because the primality check can examine nearly 10,000 divisors for a prime input.

## Workload

[`workload.json`](workload.json) covers the lower boundary, small primes and composites, a prime near the maximum, invalid upper input, and the signed 64-bit minimum.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/prime_check_naive.c`](../../../c/p/prime_check_naive.c) |
| C3 | [`c3/p/prime_check_naive.c3`](../../../c3/p/prime_check_naive.c3) |
| C++ | [`cpp/p/prime_check_naive.cpp`](../../../cpp/p/prime_check_naive.cpp) |
| Elisa | [`elisa/p/prime_check_naive.elisa`](../../../elisa/p/prime_check_naive.elisa) |
| Nim | [`nim/p/prime_check_naive.nim`](../../../nim/p/prime_check_naive.nim) |
| Odin | [`odin/p/prime_check_naive.odin`](../../../odin/p/prime_check_naive.odin) |
| Rust | [`rust/p/prime_check_naive.rs`](../../../rust/p/prime_check_naive.rs) |
| V | [`v/p/prime_check_naive.v`](../../../v/p/prime_check_naive.v) |
| Zig | [`zig/p/prime_check_naive.zig`](../../../zig/p/prime_check_naive.zig) |

## Pinned source

- Go [`primecheck.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/prime/primecheck.go)
