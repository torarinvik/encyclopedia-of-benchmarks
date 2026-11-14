# Quadratic-form normal form over GF(2) — in progress

This reserved profile reduces a quadratic form over GF(2) by an invertible
linear change of coordinates. It is distinct from ordinary binary-matrix
elimination: the output must preserve a quadratic function, including its
square terms, rather than merely its polar bilinear form.

The target degree range is 1 through 100. A prospective input stores the upper
triangular coefficients of the form. A successful result supplies an
invertible binary matrix `P` and nonnegative integers `r`, `s`, and `t`, with
`s+t <= 1` and `2*r+2*s+t <= n`. Writing `y = P*x`, the reduced expression is
the XOR of `r` products `y[2k]*y[2k+1]`, optionally one term
`y[j] ^ (y[j] & y[j+1]) ^ y[j+1]`, or one remaining linear/square term.
Unused coordinates contribute zero.

The draft byte-output ABI accepts `[n, rows...]`. Each upper-triangular row is
encoded in `ceil(n/63)` nonnegative signed 64-bit words, least-significant
chunk first. Bit `j` is the coefficient of `x[i]*x[j]`; lower-triangular and
out-of-range bits must be zero. The exact input length is
`1+n*ceil(n/63)`, at most 201 words; the parseable extra-word limit is 202.
Successful output starts with single-byte `r`, `s`, and `t`, followed by `n`
rows of `ceil(n/8)` bytes containing `P` in little-endian bit order. Unused
bits are zero. Success returns the byte count (at most 1303); malformed or
null input returns `-1`, null or short output returns `-2`, and a failed
internal invariant returns `-4`. Errors leave output unchanged.

The byte-output harness compares exact results, so this profile specifies a
deterministic basis, not merely any valid normal form. Begin with the unit
vectors in index order. Repeatedly take the lexicographically first pair of
remaining positions whose polar product is one, and orthogonalize the other
vectors against it without changing their order. Normalize each non-anisotropic
plane and append it in discovery order; collect anisotropic planes in discovery
order. Combine the last two collected anisotropic planes at a time, appending
the two resulting hyperbolic planes. Choose the first nonzero quadratic value
in the remaining radical, clear the other radical values with that vector, and
use it to absorb a remaining anisotropic plane if necessary. Append the
remaining anisotropic plane, nonzero radical vector, and zero radical vectors
after the hyperbolic planes, then invert the basis matrix. The precise
two-plane basis choices are given by the independently written construction
reference; ports and reference need static review for byte-for-byte agreement.
The symbolic validator additionally accepts any valid normal form, and checks
mathematical correctness independently of that deterministic ordering.

The uncompiled [C draft](../../../c/q/quadratic_form_gf2_normal_form.c)
uses bounded two-word vectors, polar-pair searches, basis changes, and binary
Gauss–Jordan inversion. A conservative bound for its pair search is O(n⁴)
bit-row operations and its storage is O(n²) bits for fixed-width words. The
degree is bounded at 100; these bounds and the implementation need review.

The [construction-reference draft](reduction_reference.py) separates
nondegenerate planes from the polar radical, combines pairs of anisotropic
planes, and uses a nonzero radical term when present. It then inverts the
constructed basis to return `P` in the declared direction. Its direct
re-evaluation of the quadratic form is intended for reference use; the
benchmark implementation still needs its own algorithm and complexity bound.

The separate [result-validator draft](result_validator.py) verifies
matrix rank and compares the two forms on all basis vectors and pairs. Since
quadratic polynomials over GF(2) are determined by their degree-one and
degree-two coefficients, this checks equality without exhaustive enumeration.
Neither draft has been executed; the validator does not construct the normal form.
An uncompiled [Rust draft](../../../rust/q/quadratic_form_gf2_normal_form.rs)
uses bounded `u128` vectors and the same serialized contract. An uncompiled
[C++ draft](../../../cpp/q/quadratic_form_gf2_normal_form.cpp) uses fixed-size
bitsets. An uncompiled [Elisa draft](../../../elisa/q/quadratic_form_gf2_normal_form.elisa)
uses bounded input/output views and fixed-size vectors. An uncompiled
[Zig draft](../../../zig/q/quadratic_form_gf2_normal_form.zig) also uses
bounded `u128` vectors; the [Nim draft](../../../nim/q/quadratic_form_gf2_normal_form.nim)
uses fixed pairs of 64-bit words, as does the uncompiled
[V draft](../../../v/q/quadratic_form_gf2_normal_form.v) and the uncompiled
[Odin draft](../../../odin/q/quadratic_form_gf2_normal_form.odin). An uncompiled
[C3 draft](../../../c3/q/quadratic_form_gf2_normal_form.c3) also uses two-word
vectors. An uncompiled [Mojo draft](../../../mojo/q/quadratic_form_gf2_normal_form.mojo)
completes the ten-language source set. A small hand-derived workload includes
anisotropic-plane combination, radical absorption, and a 16-coordinate zero
form. An ABI
reference adapter and byte-output suite registration are drafted. The
verifier source specifies all upper-triangular forms through degree four,
generated forms through degree 100, explicit cross-chunk and highest-coordinate
cases, and checks each reference result with the separate symbolic validator. All of this integration
is unexecuted and requires review; no implementation has been verified.

The [Library Checker proposal](https://github.com/yosupo06/library-checker-problems/issues/1398)
is used only to identify the algorithmic objective. The contract and
validator above are independently written; no proposal code, text, or
fixtures have been copied. The linked issue is a proposal, not a claim of an
accepted task. The repository's shared coverage ledger records this work as
reserved to prevent duplicate implementation.
