# Gaussian prime classification

This package classifies a bounded Gaussian integer `a+bi` as irreducible in
`Z[i]`. In this Euclidean domain, irreducibility and primality are equivalent.
The benchmark implements the classification theorem using exact integer
arithmetic; it does not factor arbitrary Gaussian integers.

## Contract and bounds

The exported symbol is `gaussian_prime_classifier` in the
`i64_array_scalar` family. Input is exactly `[a,b]`, where both signed
coordinates lie in `[-10000,10000]`. Return `1` for a Gaussian prime and `0`
for zero, a unit, or a reducible element. Null input, a malformed frame, or a
coordinate outside the range returns `-1`.

For an axis element, the nonzero absolute coordinate must be an ordinary prime
congruent to 3 modulo 4. With both coordinates nonzero, `a*a+b*b` must be an
ordinary prime. Zero and units are excluded by these cases. Signs do not
change the result.

Input bounds are checked before absolute value or multiplication. Every valid
norm is at most `2*10000^2 = 200000000`; coordinate squares, their sum,
trial divisors, and divisor products therefore fit signed 64-bit arithmetic.
Out-of-range values, including `INT64_MIN` and `INT64_MAX`, return `-1`
without attempting a norm calculation. Native ports use constant scalar state
and a conservative 128-byte workspace allowance; they allocate no arrays or
heap storage.

## References and distinction

The primary reference applies the axis/norm criterion and tests ordinary
primality by odd trial divisors up to the integer square root. The independent
reference builds a sieve through 14,142, then checks norm factors using the
prime table. This provides a separate primality implementation while keeping
the same mathematical classification.

No local package classifies Gaussian primes. Existing Gaussian-integer work
covers arithmetic such as Gaussian gcd, which is a different operation.

The theorem is described in Al Faisal's [University of Waterloo Lecture 26
notes](https://math.uwaterloo.ca/~f2alfais/notes/pm340-notes.pdf), and is also
formalized in the Archive of Formal Proofs' [Gaussian Integers development,
§1.6.4](https://isa-afp.org/browser_info/current/AFP/Gaussian_Integers/document.pdf).
RosettaCodeData's pinned score-25 [popular-task title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
was used for discovery only.

## Workload and files

[`workload.json`](workload.json) covers zero, units, both axis cases, signed
coordinates, prime and composite norms, the accepted coordinate boundary,
malformed frames, out-of-bound coordinates, and signed 64-bit extremes.
[`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py) implement the two references.
[`verify_workload.py`](verify_workload.py) reconciles fixture results against
both references; [`check_inventory.py`](check_inventory.py) checks static
source presence and metadata. Neither helper has been run.

## Native ports

The package is registered in the shared `i64_array_scalar` runner and verifier.

| Language | Source |
|---|---|
| C | [`gaussian_prime_classifier.c`](../../../c/g/gaussian_prime_classifier.c) |
| C3 | [`gaussian_prime_classifier.c3`](../../../c3/g/gaussian_prime_classifier.c3) |
| C++ | [`gaussian_prime_classifier.cpp`](../../../cpp/g/gaussian_prime_classifier.cpp) |
| Elisa | [`gaussian_prime_classifier.elisa`](../../../elisa/g/gaussian_prime_classifier.elisa) |
| Mojo | [`gaussian_prime_classifier.mojo`](../../../mojo/g/gaussian_prime_classifier.mojo) |
| Nim | [`gaussian_prime_classifier.nim`](../../../nim/g/gaussian_prime_classifier.nim) |
| Odin | [`gaussian_prime_classifier.odin`](../../../odin/g/gaussian_prime_classifier.odin) |
| Rust | [`gaussian_prime_classifier.rs`](../../../rust/g/gaussian_prime_classifier.rs) |
| V | [`gaussian_prime_classifier.v`](../../../v/g/gaussian_prime_classifier.v) |
| Zig | [`gaussian_prime_classifier.zig`](../../../zig/g/gaussian_prime_classifier.zig) |

See [RIGHTS.md](RIGHTS.md) and [INVENTORY.md](INVENTORY.md) for provenance
and the static package inventory.
