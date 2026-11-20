# Complex Laguerre polynomial root

This benchmark applies one bounded Laguerre correction sequence to a real
polynomial while evaluating at a complex starting point. It returns one root
estimate; it does not deflate the polynomial or enumerate the remaining roots.
This makes the supplied starting seed and the derivative-based correction part
of the measured procedure.

This is distinct from [finite-field polynomial root finding](../../p/polynomial_root_finding/README.md),
which isolates roots over `F_998244353`, and [Ridders root finding](../../r/ridders_root_finding/README.md),
which solves bracketed real scalar functions. It also differs from the local
[Durand–Kerner cubic profile](../../d/durand_kerner_roots/README.md), which updates
all roots of one fixed cubic simultaneously; Durand–Kerner is used only as the
independent reference here.

## Contract

The `float64_slice_io` symbol is
`laguerre_complex_polynomial_root(input, input_length, output,
output_capacity)`. Input is the exact-integer binary64 frame
`[degree, a0, ..., a_degree, start_re_milli, start_im_milli,
tolerance_micro, max_iterations]`, with coefficients in ascending power
order. Degree is 2 through 6, every coefficient is in `[-16,16]`, and the
leading coefficient is nonzero. Each seed coordinate is an integer in
`[-4000,4000]` and represents that value divided by 1000. The tolerance field
is 1 through 1000 and represents that value divided by 1,000,000. The update
cap is 8 through 128. The exact frame length is `degree+6`; maximum valid and
parseable lengths are 12 and 13.

The result is `[real, imaginary]` and success returns 2. Invalid input returns
`-1`; null or undersized output returns `-2`; non-finite arithmetic, a zero
selected denominator, or failure to meet the residual criterion by the update
cap returns `-3`. Validation precedes output-buffer checking, and no error
status writes output. Workspace is two staged binary64 values.

At each iterate, the ports use descending simultaneous complex Horner
evaluation for `P`, `P'`, and `P''`. They form
`G=P'/P` and `H=G^2-P''/P`, then
`R=sqrt((degree-1)*(degree*H-G^2))`. The denominator is whichever of `G+R`
and `G-R` has larger magnitude; an exact magnitude tie selects `G+R`. Complex
square root is principal, with the nonnegative imaginary value on the negative
real axis. The convergence criterion is
`|P(z)| <= tau*max(1, sum_j |a_j|*|z|^j)`, where `tau` is the scaled tolerance
field. The seed is checked first, then each of at most `max_iterations`
corrections is followed by another check.

The primary oracle follows this correction recurrence. An independent
70-digit Decimal Durand–Kerner reference computes the polynomial's root set;
the verifier also checks the returned candidate with direct polynomial
evaluation and a scaled residual. The explicit failure fixture starts at zero
for `z^3+1`, where both derivative values vanish and the Laguerre denominator
is zero.

## Provenance and rights

The discovery index is the [indy256/codelibrary README](https://github.com/indy256/codelibrary).
Its [Laguerre polynomial root example](https://github.com/indy256/codelibrary/blob/main/cpp/numeric/polynom-roots.cpp)
motivated the benchmark. The ports are clean-room implementations of the
algorithmic idea; they do not reproduce that file. The standard `H` term here
includes `P''/P`, as in the textbook formulation, rather than the expression
in the discovery example. The iteration follows the mathematical description
in [Numerical Recipes, Chapter 9.5](https://www.cec.uchile.cl/cinetica/pcordero/MC_libros/NumericalRecipesinC.pdf).
The repository's [UNLICENSE](https://github.com/indy256/codelibrary/blob/main/UNLICENSE)
is recorded as discovery-source provenance only; see [RIGHTS.md](RIGHTS.md).

Fixtures and the static package inventory are in [`workload.json`](workload.json)
and [`verify_workload.py`](verify_workload.py). The independent root-set
reference is [`laguerre_complex_polynomial_root_reference.py`](../../laguerre_complex_polynomial_root_reference.py).

| Language | Source |
|---|---|
| C | [`c/l/laguerre_complex_polynomial_root.c`](../../../c/l/laguerre_complex_polynomial_root.c) |
| C3 | [`c3/l/laguerre_complex_polynomial_root.c3`](../../../c3/l/laguerre_complex_polynomial_root.c3) |
| C++ | [`cpp/l/laguerre_complex_polynomial_root.cpp`](../../../cpp/l/laguerre_complex_polynomial_root.cpp) |
| Elisa | [`elisa/l/laguerre_complex_polynomial_root.elisa`](../../../elisa/l/laguerre_complex_polynomial_root.elisa) |
| Mojo | [`mojo/l/laguerre_complex_polynomial_root.mojo`](../../../mojo/l/laguerre_complex_polynomial_root.mojo) |
| Nim | [`nim/l/laguerre_complex_polynomial_root.nim`](../../../nim/l/laguerre_complex_polynomial_root.nim) |
| Odin | [`odin/l/laguerre_complex_polynomial_root.odin`](../../../odin/l/laguerre_complex_polynomial_root.odin) |
| Rust | [`rust/l/laguerre_complex_polynomial_root.rs`](../../../rust/l/laguerre_complex_polynomial_root.rs) |
| V | [`v/l/laguerre_complex_polynomial_root.v`](../../../v/l/laguerre_complex_polynomial_root.v) |
| Zig | [`zig/l/laguerre_complex_polynomial_root.zig`](../../../zig/l/laguerre_complex_polynomial_root.zig) |
