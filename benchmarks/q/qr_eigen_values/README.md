# QR eigenvalues

This package measures the pinned shifted QR iteration for real symmetric matrices. It uses the `float64_slice_io` ABI and returns two approximate eigenvalues in the source's deflation order.

## Contract

Input is `[2, a00, a01, a10, a11]`, representing a 2 by 2 row-major matrix. Entries must be exact integers in `[-9,9]`; the matrix must be symmetric, its off-diagonal entry must be nonzero, and its diagonal entries must differ. These bounds avoid the source's zero-column QR cases and the equal-diagonal case where its saved-shift value is not an eigenvalue. All accepted matrices have distinct real eigenvalues and the shifted iteration converges.

The source repeatedly uses the bottom-right entry as the shift, subtracts it from each active diagonal, factors the shifted matrix with the pinned column-wise classical Gram-Schmidt QR decomposition, computes `R*Q`, and adds the shift back. It checks the bottom-left entry against `1e-10` in C and machine epsilon in C++; the shared output tolerance is `1e-8` to allow that extra refinement. On deflation, the source stores the shifted value at the last active index and finally places the remaining top-left value at index zero. Values are returned in that order and are not sorted.

Invalid dimensions, framing, entries, symmetry, or excluded matrix shapes return `-1`. Null output or capacity below two returns `-2` without writes. Output has two binary64 values. The workload uses finite integer matrices and fixed small dimensions so every accepted operation stays bounded.

## Pinned sources

- C [`qr_eigen_values.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/numerical_methods/qr_eigen_values.c), commit `e5dad3fa8def3726ec850ca66a7f51521f8ad393`, symbol `eigen_values`.
- C++ [`qr_eigen_values.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/qr_eigen_values.cpp), commit `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`, symbol `qr_algorithm::eigen_values`.
- The C++-1 source at commit `0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680` has the same algorithm and threshold as the C++ source.
- C and C++ both use the classical Gram-Schmidt implementation documented in [`qr_decompose`](../qr_decompose/README.md).

See the [workload](workload.json) and [oracle](../../qr_eigen_values_oracle.py).
