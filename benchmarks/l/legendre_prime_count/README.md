# Legendre prime count

This package returns `π(x)`, the number of primes no greater than `x`, using Legendre's prime-counting formula. The mathematical reference is [MathWorld's Legendre formula](https://mathworld.wolfram.com/LegendresFormula.html); the operation is the one specified by [Library Checker Counting Primes](https://judge.yosupo.jp/problem/counting_primes).

## Contract

The exported scalar function is `int64_t legendre_prime_count(int64_t x)` at the C ABI. Inputs in `[0, 10000]` return `π(x)`; all other signed 64-bit inputs return `-1`. Values below 2 return zero.

## Method and bounds

For `x >= 2`, each port sieves the primes through `floor(sqrt(x))` and lets `a = π(floor(sqrt(x)))`. It evaluates

`π(x) = φ(x, a) + a - 1`,

where `φ(x,a)` counts positive integers at most `x` that are divisible by none of the first `a` primes. The recursive inclusion-exclusion recurrence is `φ(x,0)=x` and `φ(x,a)=φ(x,a-1)-φ(floor(x/p_a),a-1)`, with direct base cases for one prime and for `x < p_a`. The maximum has `a=25`; the recursion depth is at most 25 and its uncached state count is bounded by `O(a*x)` for this profile.

This shares the `π(x)` result operation with [`prime_pi_sequence`](../../p/prime_pi_sequence/README.md) and [`meissel_lehmer_prime_count`](../../m/meissel_lehmer_prime_count/README.md), but uses a different algorithm. The former incrementally trial-divides a short sequence; the latter applies Lehmer's formula with prime and semiprime corrections and supports inputs through `10^8`. This package isolates Legendre's partial-sieve formula at a smaller bound. Existing sieve packages directly enumerate the range rather than evaluate this formula.

The primary oracle implements Legendre's recurrence. A separate direct Sieve of Eratosthenes oracle checks fixtures independently. See [workload.json](workload.json) and [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/l/legendre_prime_count.c`](../../../c/l/legendre_prime_count.c) |
| C3 | [`c3/l/legendre_prime_count.c3`](../../../c3/l/legendre_prime_count.c3) |
| C++ | [`cpp/l/legendre_prime_count.cpp`](../../../cpp/l/legendre_prime_count.cpp) |
| Elisa | [`elisa/l/legendre_prime_count.elisa`](../../../elisa/l/legendre_prime_count.elisa) |
| Mojo | [`mojo/l/legendre_prime_count.mojo`](../../../mojo/l/legendre_prime_count.mojo) |
| Nim | [`nim/l/legendre_prime_count.nim`](../../../nim/l/legendre_prime_count.nim) |
| Odin | [`odin/l/legendre_prime_count.odin`](../../../odin/l/legendre_prime_count.odin) |
| Rust | [`rust/l/legendre_prime_count.rs`](../../../rust/l/legendre_prime_count.rs) |
| V | [`v/l/legendre_prime_count.v`](../../../v/l/legendre_prime_count.v) |
| Zig | [`zig/l/legendre_prime_count.zig`](../../../zig/l/legendre_prime_count.zig) |
