# Meissel–Lehmer Prime Count

Return the prime-counting function `π(x)`, the number of primes no greater than
`x`, using the Meissel–Lehmer method described by [OI Wiki](https://en.oi-wiki.org/math/meissel-lehmer/).
The ports are clean-room implementations based on the algorithm description.

## Contract

The scalar input is an integer `x` in `[0, 100000000]`. The result is `π(x)`;
inputs outside this range return `-1`. The bound allows a compact sieve for
values through `sqrt(x)` while keeping the input large enough to separate this
prime-counting method from the repo's small range sieves and sequence ports.

## Algorithm and bounds

The implementation sieves primes and prefix counts through `10000`, then uses
Lehmer's formula with integer fourth, square, and cube roots. The `φ(x,a)` term
counts integers through `x` not divisible by the first `a` primes; recursive
inclusion/exclusion evaluates it with a bounded memo table for small `x`. The
formula subtracts prime and semiprime contributions to obtain `π(x)`. The
largest result is `π(10^8) = 5,761,455`.

This package is distinct from the local Eratosthenes, Atkin, linear, and
segmented sieve benchmarks, which directly enumerate primes only over bounded
small ranges. `prime_pi_sequence` uses incremental trial division for indices
up to `999`. `sum_of_multiplicative_function_large` uses Min_25 to sum a
different multiplicative function; its internal prime-prefix calculations do
not provide a standalone prime-count operation. The independent oracle counts
primes using a segmented sieve rather than Lehmer's formula.

See [`workload.json`](workload.json) and the independent
[segmented-sieve oracle](../../meissel_lehmer_prime_count_oracle.py). No
implementation has been run or compiled.

## Language ports

| Language | Source |
|---|---|
| C | [`c/m/meissel_lehmer_prime_count.c`](../../../c/m/meissel_lehmer_prime_count.c) |
| C3 | [`c3/m/meissel_lehmer_prime_count.c3`](../../../c3/m/meissel_lehmer_prime_count.c3) |
| C++ | [`cpp/m/meissel_lehmer_prime_count.cpp`](../../../cpp/m/meissel_lehmer_prime_count.cpp) |
| Elisa | [`elisa/m/meissel_lehmer_prime_count.elisa`](../../../elisa/m/meissel_lehmer_prime_count.elisa) |
| Nim | [`nim/m/meissel_lehmer_prime_count.nim`](../../../nim/m/meissel_lehmer_prime_count.nim) |
| Odin | [`odin/m/meissel_lehmer_prime_count.odin`](../../../odin/m/meissel_lehmer_prime_count.odin) |
| Rust | [`rust/m/meissel_lehmer_prime_count.rs`](../../../rust/m/meissel_lehmer_prime_count.rs) |
| V | [`v/m/meissel_lehmer_prime_count.v`](../../../v/m/meissel_lehmer_prime_count.v) |
| Zig | [`zig/m/meissel_lehmer_prime_count.zig`](../../../zig/m/meissel_lehmer_prime_count.zig) |
| Mojo | [`mojo/m/meissel_lehmer_prime_count.mojo`](../../../mojo/m/meissel_lehmer_prime_count.mojo) |
