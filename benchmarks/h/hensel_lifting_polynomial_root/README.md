# Hensel lifting of a simple polynomial root

This benchmark lifts a supplied simple root of an integer polynomial from a
prime modulus to a bounded prime-power modulus. It exposes the iterative
Hensel correction directly, rather than searching the full residue space.

## Contract

The ABI is `i64_array_scalar`; the exported symbol is
`hensel_lifting_polynomial_root`. Input is
`[degree,prime,exponent,root_mod_prime,c0,...,c_degree]`, where the polynomial
is `f(x)=c0+c1*x+...+c_degree*x^degree`. The degree is 1..4, `prime` is a
prime in 2..43, the exponent is 1..6, and `prime^exponent <= 100000`.
Coefficients lie in `[-1000,1000]`. The seed must be in `[0,prime)`, satisfy
`f(seed)=0 mod prime`, and be simple: `f'(seed)` must be nonzero modulo prime.
The exact frame length is `degree+5`; maximum valid and parseable lengths are
9 and 10 words. Invalid or null input returns `-1`.

The result is the unique root in `[0,prime^exponent)` congruent to the supplied
seed modulo prime. At stage `j`, with current root `r` modulo `p^j`, compute
`q=(f(r) mod p^(j+1))/p^j`. The next base-p digit is
`t=-q*(f'(seed)^-1 mod p) mod p`, and the lifted root is
`r+t*p^j`. The simple-root condition makes the derivative invertible and
guarantees one root in the seed's residue class at every stage. A small
candidate scan computes the inverse modulo `p` safely for the bounded prime.

All polynomial evaluations use modular Horner evaluation. Each modulus is at
most 100,000; reduced Horner products are below `10^10`, and derivative and
inverse arithmetic are also far below signed 64-bit limits. The declared
result bound is 83,520, since the largest accepted prime power under the `p`
and exponent limits is `17^4 = 83,521`. The independent reference scans every
residue in the seed class modulo `p` and checks the polynomial directly,
rather than applying the digit-correction recurrence.

This is distinct from [`tonelli_shanks`](../../t/tonelli_shanks/README.md) and
[`cipolla_modular_square_root`](../../c/cipolla_modular_square_root/README.md),
which find roots over a prime field using different prime-modulus algorithms.
This profile starts from a supplied root and lifts a general polynomial root
through successive powers of the same prime.

## Provenance

The prime-power root-lifting procedure is described by Victor Shoup,
[*A Computational Introduction to Number Theory and Algebra*](https://www.shoup.net/ntb/ntb-v2_0.pdf),
§12.5.2. The simple-root uniqueness condition and Newton/Hensel formulation
are also documented in [FLINT's Hensel-lifting notes](https://flintlib.org/doc/algorithms/p-adic/hensel-lifting.html).
The package ports and references are clean-room implementations of the
mathematical algorithm; no published code or prose is copied. See
[`RIGHTS.md`](RIGHTS.md).

| Language | Source |
| --- | --- |
| C | [c/h/hensel_lifting_polynomial_root.c](../../../c/h/hensel_lifting_polynomial_root.c) |
| C3 | [c3/h/hensel_lifting_polynomial_root.c3](../../../c3/hensel_lifting_polynomial_root.c3) |
| C++ | [cpp/h/hensel_lifting_polynomial_root.cpp](../../../cpp/h/hensel_lifting_polynomial_root.cpp) |
| Elisa | [elisa/h/hensel_lifting_polynomial_root.elisa](../../../elisa/h/hensel_lifting_polynomial_root.elisa) |
| Mojo | [mojo/h/hensel_lifting_polynomial_root.mojo](../../../mojo/h/hensel_lifting_polynomial_root.mojo) |
| Nim | [nim/h/hensel_lifting_polynomial_root.nim](../../../nim/h/hensel_lifting_polynomial_root.nim) |
| Odin | [odin/h/hensel_lifting_polynomial_root.odin](../../../odin/h/hensel_lifting_polynomial_root.odin) |
| Rust | [rust/h/hensel_lifting_polynomial_root.rs](../../../rust/h/hensel_lifting_polynomial_root.rs) |
| V | [v/h/hensel_lifting_polynomial_root.v](../../../v/h/hensel_lifting_polynomial_root.v) |
| Zig | [zig/h/hensel_lifting_polynomial_root.zig](../../../zig/h/hensel_lifting_polynomial_root.zig) |

Fixtures include linear and quadratic lifts, the prime-two edge case, a
large capped prime power, exponent one, maximum-degree framing, nonsimple and
invalid seeds, a composite base, an over-cap modulus, malformed input, and a
null frame. `verify_workload.py` describes a static inventory check; it is not
part of the benchmark call.
