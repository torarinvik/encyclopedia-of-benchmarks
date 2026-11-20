# Fast prime sums

Return the sum of every prime no greater than a bounded `n`, using a
Meissel–Lehmer weighted partial-sieve recurrence. This is distinct from
[`meissel_lehmer_prime_count`](../../m/meissel_lehmer_prime_count/README.md),
which counts primes, and from the Min_25 sieve in
[`sum_of_multiplicative_function_large`](../../s/sum_of_multiplicative_function_large/README.md),
which sums a general multiplicative-function family. The local Problem 10
profile uses an odd-only direct sieve over a small fixed range.

## Contract

- ABI: `i64_scalar`; exported symbol: `fast_prime_sums`.
- Input: one signed 64-bit integer `n` in `[0, 1,000,000,000]`.
- Return `sum_{p prime, p<=n} p`; return `-1` outside the range.
- The maximum result is `24,739,512,092,254,535`, which fits signed 64-bit.

The primary sieves a prefix through 32,000, tabulates weighted `phi(n,a)` for
small arguments, and applies the Meissel–Lehmer prime-sum correction. Its
largest `phi(n,0)=n(n+1)/2` is below signed 64-bit at the chosen input bound.
The independent reference uses a segmented sieve through `10^6`; for larger
fixture points it uses the independently published values at `10^8` and
`10^9` from [OEIS A046731](https://oeis.org/A046731). It intentionally does not
evaluate arbitrary large points.

See [workload](workload.json), [primary reference](primary_oracle.py),
[independent reference](independent_oracle.py), and
[rights/provenance](RIGHTS.md). The pinned Algovault source is an algorithm
reference only: [Fast Prime Sums](https://github.com/sgtlaugh/algovault/blob/c4e8beb105e84a31596b9222f9b3282c0dc78dd2/code_library/number_theory/fast_prime_sums.cpp).

## Language ports

| Language | Source |
|---|---|
| C | [`c/f/fast_prime_sums.c`](../../../c/f/fast_prime_sums.c) |
| C3 | [`c3/f/fast_prime_sums.c3`](../../../c3/f/fast_prime_sums.c3) |
| C++ | [`cpp/f/fast_prime_sums.cpp`](../../../cpp/f/fast_prime_sums.cpp) |
| Elisa | [`elisa/f/fast_prime_sums.elisa`](../../../elisa/f/fast_prime_sums.elisa) |
| Mojo | [`mojo/f/fast_prime_sums.mojo`](../../../mojo/f/fast_prime_sums.mojo) |
| Nim | [`nim/f/fast_prime_sums.nim`](../../../nim/f/fast_prime_sums.nim) |
| Odin | [`odin/f/fast_prime_sums.odin`](../../../odin/f/fast_prime_sums.odin) |
| Rust | [`rust/f/fast_prime_sums.rs`](../../../rust/f/fast_prime_sums.rs) |
| V | [`v/f/fast_prime_sums.v`](../../../v/f/fast_prime_sums.v) |
| Zig | [`zig/f/fast_prime_sums.zig`](../../../zig/f/fast_prime_sums.zig) |
