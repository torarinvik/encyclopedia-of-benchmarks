# One-sided Jacobi singular values

This bounded profile computes the singular spectrum of a small real matrix by cyclic one-sided Jacobi rotations. It measures the singular-value kernel as a scalar fixed-point signature, rather than returning singular vectors whose signs and repeated-value bases are non-unique.

## Contract

The `i64_array_scalar` input is `[m,n,A00,A01,...]`, with the matrix in row-major order, `1<=n<=m<=6`, and entries in `[-8,8]`. The frame must contain exactly `2+m*n` values. Invalid or out-of-range input returns `-1`.

The algorithm repeatedly orthogonalizes each pair of matrix columns in increasing `(p,q)` order. A sweep stops when every pair's inner product is at most `1e-14*sqrt(alpha*beta)` in magnitude, where `alpha` and `beta` are the squared column norms. At most 128 sweeps are allowed. The singular values are the final column norms, sorted descending. The result is `round_half_up(1000 * sum((j+1)*sigma[j]))`, with zero-based `j`. This makes the complete sorted spectrum affect the timed scalar result. Since the Frobenius norm is at most 48 and the nuclear norm is at most `sqrt(6)*48`, the weighted signature is below 706,000.

For `s` sweeps the time is `O(s*m*n^2)` and the working storage is `O(m*n+n)`. The input bounds keep all intermediate values finite. The independent reference diagonalizes `A^T A` with symmetric Jacobi rotations and takes square roots of the resulting nonnegative eigenvalues.

The profile is distinct from [`qr_eigen_values`](../qr_eigen_values/README.md), which computes eigenvalues of a supplied symmetric matrix, and from polynomial-regression profiles that use an SVD internally but measure a different end-to-end operation. Discovery came from the pinned RosettaCodeData title index; algorithm details follow Drmač and Veselić's [one-sided Jacobi SVD work](https://doi.org/10.1137/050639193), with the classic Golub–Kahan paper as historical context ([PDF](https://gforgeron.gitlab.io/cisd/internal/page/supports/if345/svd/golub-kahan-1965.pdf)). No code, task text, examples, or fixtures were reused.

The package has ten language ports, primary and independent references, a bounded workload, rights/provenance, a static inventory checker, and `i64_array_scalar` suite registration. No compiler, test, helper, checker, or benchmark was run.

| Language | Source |
| --- | --- |
| C | [C](../../../c/o/one_sided_jacobi_svd.c) |
| C3 | [C3](../../../c3/o/one_sided_jacobi_svd.c3) |
| C++ | [C++](../../../cpp/o/one_sided_jacobi_svd.cpp) |
| Elisa | [Elisa](../../../elisa/o/one_sided_jacobi_svd.elisa) |
| Mojo | [Mojo](../../../mojo/o/one_sided_jacobi_svd.mojo) |
| Nim | [Nim](../../../nim/o/one_sided_jacobi_svd.nim) |
| Odin | [Odin](../../../odin/o/one_sided_jacobi_svd.odin) |
| Rust | [Rust](../../../rust/o/one_sided_jacobi_svd.rs) |
| V | [V](../../../v/o/one_sided_jacobi_svd.v) |
| Zig | [Zig](../../../zig/o/one_sided_jacobi_svd.zig) |
