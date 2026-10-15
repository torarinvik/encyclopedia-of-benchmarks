# Mersenne prime predicate

## Contract

Return `1` when the input value `n` is a Mersenne prime, meaning `n` is prime and `n + 1` is a power of two. Return `0` for zero and for in-range non-Mersenne-primes. Inputs from `1` through `2,147,483,647` are accepted; negative inputs and values above that limit return `-1`. Zero is kept as the pinned source's false result.

The scalar ABI is `int64_t mersenne_prime(int64_t n)`. The implementation first checks the Mersenne form and only runs trial-division primality when that check succeeds, matching the Julia source's short-circuit order. The maximum accepted value makes `n + 1` safe in signed 64-bit arithmetic. Julia uses `/=` while reducing `n + 1`; on this positive bounded domain, each division is exact and reaches an odd value. The sibling Julia `prime_check` uses trial division through the integer square root.

## Source behavior and related candidates

The pinned Julia `is_mersenne_prime(n)` receives the candidate value itself. It reduces `n + 1` by factors of two and checks that the remainder is one before calling `prime_check(n)`. Its `get_mersenne_primes(limit)` enumerates candidate values from 1 through the inclusive limit. The source does not define behavior for `n = -1`: its first value becomes zero and the even-reduction loop does not terminate. This benchmark returns `-1` for negative values. The source returns false for zero and one.

The existing `prime_check` benchmark covers primality alone; this benchmark adds the Mersenne-form condition. Exponent-based Lucas–Lehmer routines use a different input contract and are outside this scalar candidate-value benchmark.

## Workload

[`workload.json`](workload.json) covers zero, small Mersenne primes, Mersenne composites, a large source example, the largest accepted signed-32-bit value, and both invalid boundaries.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/mersenne_prime.c`](../../../c/m/mersenne_prime.c) |
| C3 | [`c3/m/mersenne_prime.c3`](../../../c3/m/mersenne_prime.c3) |
| C++ | [`cpp/m/mersenne_prime.cpp`](../../../cpp/m/mersenne_prime.cpp) |
| Elisa | [`elisa/m/mersenne_prime.elisa`](../../../elisa/m/mersenne_prime.elisa) |
| Nim | [`nim/m/mersenne_prime.nim`](../../../nim/m/mersenne_prime.nim) |
| Odin | [`odin/m/mersenne_prime.odin`](../../../odin/m/mersenne_prime.odin) |
| Rust | [`rust/m/mersenne_prime.rs`](../../../rust/m/mersenne_prime.rs) |
| V | [`v/m/mersenne_prime.v`](../../../v/m/mersenne_prime.v) |
| Zig | [`zig/m/mersenne_prime.zig`](../../../zig/m/mersenne_prime.zig) |

## TheAlgorithms reference

- [Julia `mersenne_prime.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/mersenne_prime.jl)
- [Julia `prime_check.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/prime_check.jl)
