# Cyclotomic polynomial coefficients

This bounded profile computes the integer coefficients of the `n`th
cyclotomic polynomial, `Phi_n(x)`, for `1 <= n <= 32`. The input is one signed
64-bit word `[n]`. The output is the coefficient vector in ascending degree
order, without a count prefix. The byte result is exactly `8*(phi(n)+1)`.

The native ports compute `Phi_1=x-1`, then process `k=2..n` in order. For each
`k`, they multiply the already-computed `Phi_d` for every proper divisor `d`
of `k`, and divide `x^k-1` by that monic product using exact integer
polynomial long division. Malformed input returns `-1`; a null or undersized
output returns `-2`. Validation and the full computation precede the
capacity check, and either error leaves the caller's output untouched.

## Bounds and arithmetic

For a degree-`m` cyclotomic polynomial, each coefficient is an elementary
symmetric sum of `m` roots of modulus one, so its absolute value is at most
`binomial(m,j)` at position `j`; its coefficient 1-norm is at most `2^m`.
The product of proper-divisor polynomials at index `k` therefore has 1-norm
at most `2^(k-phi(k)) <= 2^31`. During long division, the quotient is a
partial selection of coefficients of `Phi_k`, whose 1-norm is at most
`2^phi(k)`. The complete remainder is bounded in 1-norm by
`2 + 2^k <= 2^32+2`; even an individual in-place subtraction step is below
`2^33+2`. Products and sums used by convolution are bounded by the same
1-norm products. These bounds are far below signed 64-bit limits.

The independent Newton-identity reference is bounded as well: with
`m=phi(n)<=30`, each primitive-root power sum has magnitude at most `m` and
each coefficient has magnitude at most `2^m`. A weighted Newton sum is
therefore below `m^2*2^m < 10^12`; the Möbius/Ramanujan divisor sums are
smaller still for `n<=32`.

The largest degree for `n<=32` is `phi(31)=30`: 31 is the largest prime at
most 32, and every composite has `phi(n)<=n/2<=16`. Thus the largest output
has 31 coefficients and 248 bytes. The fixed cache and scratch arrays use
less than 10 KiB; the declared workspace allowance is 16 KiB and excludes the
caller-owned input and output buffers.

## Independent reference

`primary_oracle.py` follows the recursive proper-divisor product and exact
quotient. `independent_oracle.py` instead obtains power sums of primitive
roots from Ramanujan sums, then applies Newton identities to recover the
monic coefficients. The latter shares neither the quotient recurrence nor
its polynomial-product steps. `verify_workload.py` is authored to compare
both references with each hand-pinned workload result; it has not been run.

## Sources and distinction

The [Encyclopedia of Mathematics entry on cyclotomic
polynomials](https://encyclopediaofmath.org/wiki/Cyclotomic_polynomials)
states the recursive definition by division by the product for proper
divisors and also gives the Möbius-product expression. Arnold and Monagan,
[“Calculating Cyclotomic Polynomials”](https://doi.org/10.1090/S0025-5718-2011-02467-1),
*Mathematics of Computation* 80(276), 2011, discusses recursive polynomial
division and alternative constructions. The pinned [RosettaCodeData popular
task index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
is used only to discover the “Cyclotomic-polynomial” title.

This is distinct from the local Möbius-function profile, which returns one
integer value, and polynomial interpolation, evaluation, or formal-series
packages, which do not construct the integer polynomial whose roots are the
primitive `n`th roots of unity. See [`RIGHTS.md`](RIGHTS.md) for the
clean-room and source-use note.

## Ports

| Language | Source |
|---|---|
| C | [cyclotomic_polynomial_coefficients.c](../../../c/c/cyclotomic_polynomial_coefficients.c) |
| C3 | [cyclotomic_polynomial_coefficients.c3](../../../c3/c/cyclotomic_polynomial_coefficients.c3) |
| C++ | [cyclotomic_polynomial_coefficients.cpp](../../../cpp/c/cyclotomic_polynomial_coefficients.cpp) |
| Elisa | [cyclotomic_polynomial_coefficients.elisa](../../../elisa/c/cyclotomic_polynomial_coefficients.elisa) |
| Mojo | [cyclotomic_polynomial_coefficients.mojo](../../../mojo/c/cyclotomic_polynomial_coefficients.mojo) |
| Nim | [cyclotomic_polynomial_coefficients.nim](../../../nim/c/cyclotomic_polynomial_coefficients.nim) |
| Odin | [cyclotomic_polynomial_coefficients.odin](../../../odin/c/cyclotomic_polynomial_coefficients.odin) |
| Rust | [cyclotomic_polynomial_coefficients.rs](../../../rust/c/cyclotomic_polynomial_coefficients.rs) |
| V | [cyclotomic_polynomial_coefficients.v](../../../v/c/cyclotomic_polynomial_coefficients.v) |
| Zig | [cyclotomic_polynomial_coefficients.zig](../../../zig/c/cyclotomic_polynomial_coefficients.zig) |

Package-local references, workload, and inventory are included here. The
`i64_array_bytes_output` suite, shared catalog, and expansion ledger include
this profile. No programs, tests, scripts, helpers, checkers, builds,
compilers, profilers, or benchmarks have been run.
