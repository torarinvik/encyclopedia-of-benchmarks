# Polynomial resultant via half-GCD

Compute the resultant of two nonzero univariate polynomials over the field
`998244353`. This differs from [`bareiss_determinant`](../../b/bareiss_determinant/README.md),
which handles a supplied integer matrix, and from
[`difference_product`](../../d/difference_product/README.md), which computes a
special Vandermonde product of supplied points. No matching resultant package
was found in the static name and description search.

The proposed `i64_array_scalar` frame is `[m, n, f0, ..., fm, g0, ..., gn]`,
with coefficients in ascending degree order. Degrees satisfy `0 <= m,n <=
50000` and `m+n <= 99998`, so the exact frame length `m+n+4` fits the scalar
harness. Coefficients must be canonical field elements and both leading
coefficients nonzero. Return the canonical resultant; return -1 for malformed
input. The resultant of two nonzero constants is 1.

The intended benchmark kernel uses polynomial half-GCD with NTT-backed
multiplication and tracks the degree, leading-coefficient and parity factors
needed for the resultant. Its target complexity is O(M(d) log d), where
`d=max(m,n)` and M(d)=O(d log d). A direct polynomial-remainder reference and
a separate Sylvester-matrix determinant reference are supplied only for small
cases; neither is a substitute for the benchmark kernel at this bound.

The [Library Checker proposal](https://github.com/yosupo06/library-checker-problems/issues/1407)
is used as an idea index. [FLINT's algorithm overview](https://flintlib.org/doc/algorithms/polynomials/gcd.html)
describes half-GCD and resultant computation. The bounded contract,
references, and prose are independently written; no upstream text, code, or
fixtures are copied. See [RIGHTS.md](RIGHTS.md) for provenance.

Reserved and in progress: the contract, two small references, initial fixtures,
workload validator, and [C++ field-arithmetic scaffold](../../../cpp/p/polynomial_resultant_half_gcd_primitives.hpp)
are drafted. The scaffold has NTT multiplication, truncated inversion, and
polynomial division, plus forward polynomial-matrix helpers. A separate
[recursive reduction draft](../../../cpp/p/polynomial_resultant_half_gcd_reduction.hpp)
constructs a forward half-GCD matrix. An unverified [C++ kernel draft](../../../cpp/p/polynomial_resultant_half_gcd_kernel.hpp)
reconstructs resultant factors from quotient heads and full lifted remainders;
the [implementation invariants](IMPLEMENTATION_NOTES.md) explain the approach.
A [C++ scalar entry point](../../../cpp/p/polynomial_resultant_half_gcd.cpp)
validates the frame and calls the draft kernel. A separate [Rust port](../../../rust/p/polynomial_resultant_half_gcd.rs)
also drafts the NTT, half-GCD, and factor reconstruction. A [Nim draft](../../../nim/p/polynomial_resultant_half_gcd.nim)
implements the same contract. The scalar runner and verifier include draft
registration. A [V draft](../../../v/p/polynomial_resultant_half_gcd.v)
also includes the reduction and scalar entry point. These ports and the
wiring are unverified.
Nothing has been compiled or run.

An [Odin draft](../../../odin/p/polynomial_resultant_half_gcd.odin) now includes
the reduction, factor tracking, and exported entry point. It is unverified,
as are the other drafts.

A [C draft](../../../c/p/polynomial_resultant_half_gcd.c) also includes the
recursive matrix reduction, factor tracking, and an exported entry point. It
remains unverified. A [Zig draft](../../../zig/p/polynomial_resultant_half_gcd.zig)
uses an arena for temporary polynomials; its peak workspace and correctness
remain unverified.

A [C3 draft](../../../c3/p/polynomial_resultant_half_gcd.c3) now includes
the reduction, factor tracking, and scalar export. It is unverified.

A [Mojo draft](../../../mojo/p/polynomial_resultant_half_gcd.mojo) includes
the reduction, factor tracking and scalar export. It is unverified.

The [Elisa arithmetic draft](../../../elisa/p/polynomial_resultant_half_gcd.elisa)
uses views and caller-supplied scratch for NTT, inversion, division, and
forward matrix operations. A recursive reduction draft uses bounded,
caller-supplied frame storage and records quotient heads; a separate helper
drafts factor reconstruction. A top-level loop and scalar entry point now
connect these helpers. A conservative frame budget has a conditional static
bound in the notes; all ten language drafts remain unverified. Nothing has
been compiled or run.

The unexecuted [structured case builder](structured_cases.py) specifies
closed-form probes around the recursive cutoff and at the maximum frame size.
The verifier includes them without sending them to the small determinant
validator, which is intentionally limited to degree sum 32.
The verifier also drafts small dense comparisons between the two references
and dense cases crossing the recursive cutoff. Its unrun matrix checks compare
the recursive reduction to elementary Euclidean steps with a small cutoff.
The scalar harness caps input at 100002 words, matching the maximum valid frame.
The measured workload includes a degree-65 monomial-divisor case that crosses
the recursive and multiplication cutoffs; its result follows by evaluating at
the divisor's root.
