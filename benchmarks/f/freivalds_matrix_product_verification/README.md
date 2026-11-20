# Freivalds matrix-product verification

This package benchmarks Freivalds' randomized matrix-product checker with an
explicit supplied sign-vector tape. The call is a deterministic replay of the
test decisions. It does not generate randomness or claim a probabilistic
guarantee for a particular tape.

## Contract

- ABI: `i64_array_scalar`; symbol:
  `freivalds_matrix_product_verification`.
- Input is `[n,k,A[n*n],B[n*n],C[n*n],r_0[n],...,r_(k-1)[n]]`.
  Matrices are square, row-major, with `1<=n<=8`; `1<=k<=8`. Every matrix
  entry is an integer from `-3` through `3`, and each supplied vector entry is
  exactly `-1` or `+1`.
- For each vector `r`, compute `x=B*r`, `y=A*x`, and `z=C*r`. Return `1` iff
  `y=z` for every supplied vector; return `0` as soon as a round differs.
  Return `-1` for null, malformed, or out-of-domain input.
- This is the source's one-sided test over an exact integer subset of the
  real-number domain. Every correct product passes every tape. An incorrect
  product can pass a particular tape; the source's `2^-k` bound applies only
  when the `k` vectors are sampled independently and uniformly from
  `{-1,+1}^n`.
- Maximum valid/parseable input lengths are 258/259 i64 words. All
  intermediates fit signed 64-bit integers under the declared bounds.
- The primary trace costs `O(kn^2)` time and `O(n^2+kn)` storage. The
  independent reference explicitly forms `AB-C` before applying the vectors.

The false-acceptance fixture uses an incorrect candidate product and a vector
orthogonal to its error row; it documents the supplied-tape semantics. A
second vector detects the same error. The workload also includes the maximum
`n=8`, `k=8` input with zero matrices, plus correct products, signed entries,
malformed framing, invalid signs, and out-of-range matrix entries.

## Source and rights

The algorithm follows §3 of Rūsiņš Freivalds, [“Fast Probabilistic
Algorithms,” MFCS 1979, LNCS 74, pp. 57–69](https://doi.org/10.1007/3-540-09526-8_5).
The paper chooses sign vectors and compares `A(BX)` with `CX`; the fixed tape,
small integer domain, and output conventions here are local profile choices.
No source code, prose, examples, figures, or test data are copied. See
[RIGHTS.md](RIGHTS.md).

| Language | Source |
|---|---|
| C | [`c/f/freivalds_matrix_product_verification.c`](../../../c/f/freivalds_matrix_product_verification.c) |
| C3 | [`c3/f/freivalds_matrix_product_verification.c3`](../../../c3/f/freivalds_matrix_product_verification.c3) |
| C++ | [`cpp/f/freivalds_matrix_product_verification.cpp`](../../../cpp/f/freivalds_matrix_product_verification.cpp) |
| Elisa | [`elisa/f/freivalds_matrix_product_verification.elisa`](../../../elisa/f/freivalds_matrix_product_verification.elisa) |
| Mojo | [`mojo/f/freivalds_matrix_product_verification.mojo`](../../../mojo/f/freivalds_matrix_product_verification.mojo) |
| Nim | [`nim/f/freivalds_matrix_product_verification.nim`](../../../nim/f/freivalds_matrix_product_verification.nim) |
| Odin | [`odin/f/freivalds_matrix_product_verification.odin`](../../../odin/f/freivalds_matrix_product_verification.odin) |
| Rust | [`rust/f/freivalds_matrix_product_verification.rs`](../../../rust/f/freivalds_matrix_product_verification.rs) |
| V | [`v/f/freivalds_matrix_product_verification.v`](../../../v/f/freivalds_matrix_product_verification.v) |
| Zig | [`zig/f/freivalds_matrix_product_verification.zig`](../../../zig/f/freivalds_matrix_product_verification.zig) |

See the [primary oracle](primary_oracle.py), [independent exact-product
reference](independent_oracle.py), [workload](workload.json), and static
package inventory [verify_workload.py](verify_workload.py).
