# Erdős–Selfridge prime class

This package computes the plus or minus class of one supplied rational prime.
For `s=+1`, the selected neighbor is `p+1`; for `s=-1`, it is `p-1`. Class 1
means that every prime factor of the selected neighbor is 2 or 3. Otherwise,
the class is one greater than the largest class among the distinct prime
factors greater than 3. This is a recursive classification, not a test of
whether `p` is prime: the input must itself be prime.

## Contract

The exported symbol is `erdos_selfridge_prime_class` in the `i64_array_scalar`
family. Input is exactly `[p,s]`, where `2<=p<=100000`, `p` is rational prime,
and `s` is either `+1` or `-1`. Return the selected class; return `-1` for
null, malformed, out-of-range, composite, or invalid-direction input.

Formally, for each sign `s`,

`class_s(p) = max({1} ∪ {1 + class_s(q) : q>3 prime and q divides p+s})`.

Repeated prime powers do not change a class. For `p>3`, every contributing
factor `q` is smaller than `p`; along any recursion chain it is at most
`(p+1)/2`. With `p<=100000`, classes are at most 17. Selected neighbors are
at most 100001, so trial factorization, loop bounds, recursion, and results fit
signed 64-bit arithmetic. Native ports recursively factor the neighbor and
take the maximum class over distinct factors. The independent reference
sieves primes and fills class values bottom-up through the requested `p`.

The local [`gaussian_prime_classifier`](../gaussian_prime_classifier/README.md)
tests irreducibility in the Gaussian integers using an axis/norm criterion.
It does not classify rational primes by recursively examining `p+1` or
`p-1`. Generic primality and factorization packages likewise do not implement
this scored class recurrence.

## Sources and workload

The recurrence and sequence values are recorded separately for plus and minus
classes in OEIS [A126433](https://oeis.org/A126433/internal) and
[A126805](https://oeis.org/A126805/internal). The latter formulas use
`max(class(q)+1)` over distinct prime factors `q>3` of `p-1`; the plus record
does the same for `p+1`. These recurrence records are the profile's definitive
definitions. The pinned RosettaCodeData score-19 [popular-title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
was used only to discover the task title. No task code, wording, examples, or
tests were reused.

[`workload.json`](workload.json) includes both directions, classes 1 through
4, malformed and composite inputs, and null input. The references are
[`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py). The static fixture helper
[`verify_workload.py`](verify_workload.py) was authored but not run.

## Native ports

| Language | Source |
|---|---|
| C | [`erdos_selfridge_prime_class.c`](../../../c/e/erdos_selfridge_prime_class.c) |
| C3 | [`erdos_selfridge_prime_class.c3`](../../../c3/e/erdos_selfridge_prime_class.c3) |
| C++ | [`erdos_selfridge_prime_class.cpp`](../../../cpp/e/erdos_selfridge_prime_class.cpp) |
| Elisa | [`erdos_selfridge_prime_class.elisa`](../../../elisa/e/erdos_selfridge_prime_class.elisa) |
| Mojo | [`erdos_selfridge_prime_class.mojo`](../../../mojo/e/erdos_selfridge_prime_class.mojo) |
| Nim | [`erdos_selfridge_prime_class.nim`](../../../nim/e/erdos_selfridge_prime_class.nim) |
| Odin | [`erdos_selfridge_prime_class.odin`](../../../odin/e/erdos_selfridge_prime_class.odin) |
| Rust | [`erdos_selfridge_prime_class.rs`](../../../rust/e/erdos_selfridge_prime_class.rs) |
| V | [`erdos_selfridge_prime_class.v`](../../../v/e/erdos_selfridge_prime_class.v) |
| Zig | [`erdos_selfridge_prime_class.zig`](../../../zig/e/erdos_selfridge_prime_class.zig) |

See [RIGHTS.md](RIGHTS.md), [INVENTORY.md](INVENTORY.md), and
[`INVENTORY.json`](INVENTORY.json) for provenance and package files. Shared
`i64_array_scalar` runner/verifier and catalog registration are integrated.

