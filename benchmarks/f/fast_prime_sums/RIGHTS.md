# Rights and provenance

The package uses the mathematical algorithm described in the pinned Algovault
[`fast_prime_sums.cpp`](https://github.com/sgtlaugh/algovault/blob/c4e8beb105e84a31596b9222f9b3282c0dc78dd2/code_library/number_theory/fast_prime_sums.cpp):
a prime prefix sieve, a weighted partial-sieve
recurrence, and Meissel–Lehmer corrections for the sum of primes through `n`.
No source code, comments, tests, or sample harness were copied. All ten ports
and both Python references were written independently from the algorithm
description.

The large fixture values are sourced from OEIS sequence [A046731](https://oeis.org/A046731),
which records sums of primes through powers of ten. Since 10^8 and 10^9 are
composite, the values are the same for primes strictly below those limits.
