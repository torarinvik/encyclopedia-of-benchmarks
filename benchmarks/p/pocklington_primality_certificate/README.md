# Pocklington primality certificate

This bounded benchmark verifies an `n-1` primality certificate. It is separate
from [`miller_rabin`](../../m/miller_rabin/README.md) and
[`miller_rabin_primality_checker`](../../m/miller_rabin_primality_checker/README.md):
those profiles test probable-prime conditions, while acceptance here is a
deterministic proof of primality based on supplied factors of `n-1`.

## Contract

- ABI: `i64_array_scalar`; exported symbol: `pocklington_primality_certificate`.
- Input frame: `[n,k,(q_i,e_i,a_i)*k,R]`, with `3<=n<=65535`, `1<=k<=6`,
  and exact length `3+3*k` (maximum valid length 21, maximum parseable length
  22).
- The `q_i` values must be strictly increasing, distinct primes. Each exponent
  satisfies `1<=e_i<=16`; each witness satisfies `1<=a_i<n`; and `1<=R<n`.
  The supplied known part is `F=product(q_i^e_i)` and must satisfy
  `F*R=n-1`.
- Return `1` when the certificate proves `n` prime. Return `0` for a
  structurally valid certificate that is insufficient (`F^2<=n`) or has a
  failed witness congruence or gcd condition. Return `-1` for null or malformed
  input, out-of-range fields, a nonprime or unsorted `q_i`, an invalid
  exponent, or a mismatch in `F*R=n-1`. Rejection does not assert that `n` is
  composite.

## Verification method

For every supplied prime factor `q_i`, Pocklington's criterion requires a
corresponding witness `a_i` such that

`a_i^(n-1) = 1 (mod n)` and
`gcd(a_i^((n-1)/q_i)-1,n) = 1`.

If the fully factored part `F` also satisfies `F^2>n`, all prime divisors of
`n` would have to be larger than `sqrt(n)`, so the certificate proves that
`n` is prime. The primary trial-checks the supplied `q_i`, forms `F`, then
checks modular powers by repeated squaring and gcds by Euclid's algorithm.
The independent reference computes modular powers through direct repeated
multiplication and checks gcd conditions by divisor enumeration.

The criterion is due to H. C. Pocklington's 1914 paper, [*The determination
of the prime or composite nature of large numbers by Fermat's theorem*](https://upload.wikimedia.org/wikipedia/commons/e/eb/Proceedings_-_Cambridge_Philosophical_Society_%28IA_proceedingscambr18camb%29.pdf).
The theorem statement and original citation are also given in the [FLINT
primality-proving documentation](https://flintlib.org/doc/algorithms/number-theory/primality-proving.html).
Only mathematical algorithm ideas are used; no upstream source code, prose,
examples, or tests are copied.

The workload includes accepted prime certificates, insufficient known-factor
coverage, failed Fermat and gcd witnesses, malformed factor order, the maximum
21-word valid frame, a 22-word trailing-value frame, and null pointers at
zero and maximum parseable lengths. The primary is `primary_oracle.py`; the
independent reference is `independent_oracle.py`; the package-local static
inventory is `check_inventory.py` (`static_issues()` and `verify()`).

## Complexity

For at most six supplied factors, trial primality checking takes
`O(k*sqrt(n))` divisions. The primary adds `O(k*log(n))` modular and gcd
steps and uses `O(k)` space. The independent reference takes `O(k*n)` modular
multiplications and divisor checks in the worst case, with `O(k)` space.

## Language ports

| Language | Source |
|---|---|
| C | [pocklington_primality_certificate.c](../../../c/p/pocklington_primality_certificate.c) |
| C3 | [pocklington_primality_certificate.c3](../../../c3/p/pocklington_primality_certificate.c3) |
| C++ | [pocklington_primality_certificate.cpp](../../../cpp/p/pocklington_primality_certificate.cpp) |
| Elisa | [pocklington_primality_certificate.elisa](../../../elisa/p/pocklington_primality_certificate.elisa) |
| Mojo | [pocklington_primality_certificate.mojo](../../../mojo/p/pocklington_primality_certificate.mojo) |
| Nim | [pocklington_primality_certificate.nim](../../../nim/p/pocklington_primality_certificate.nim) |
| Odin | [pocklington_primality_certificate.odin](../../../odin/p/pocklington_primality_certificate.odin) |
| Rust | [pocklington_primality_certificate.rs](../../../rust/p/pocklington_primality_certificate.rs) |
| V | [pocklington_primality_certificate.v](../../../v/p/pocklington_primality_certificate.v) |
| Zig | [pocklington_primality_certificate.zig](../../../zig/p/pocklington_primality_certificate.zig) |
