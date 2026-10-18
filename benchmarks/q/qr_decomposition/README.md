# QR factorization properties

This package covers the shared square QR factorization represented by the pinned C/C++ classical Gram–Schmidt routines, the Python Householder routine, and the related Java modified Gram–Schmidt candidate. These methods can return different valid `Q` and `R` values, so the workload checks factorization properties instead of comparing raw matrices. It is distinct from [`qr_decompose`](../qr_decompose/README.md), whose direct fixtures follow the C/C++ classical projection order.

## Contract

The `float64_slice_io` input is `[dimension, A_row_major...]`. The dimension is an exact integer in `1..4`; the square matrix is row-major and contains exact integer values in `[-1,1]`. Every leading principal minor must be nonzero. This exact bounded-integer restriction implies full rank, ensures that the Python Householder routine's transformed pivot `x[0]` is nonzero at every reflection step, and bounds conditioning for the classical Gram–Schmidt property checks. Full rank alone is insufficient because the pinned routine uses `sign(x[0])` to build each reflector; if `x[0]` is zero while the remaining vector is nonzero, the reflection does not eliminate the lower entries.

The adapter computes a QR factorization, then returns three Frobenius error norms:

1. `||A - Q*R||`, the reconstruction error.
2. `||Qᵀ*Q - I||`, the orthogonality error.
3. The Frobenius norm of the strictly lower-triangular part of `R`.

The ideal output is `[0,0,0]`; actual floating-point residuals are compared with absolute and relative tolerances of `1e-8`. The C and C++ example wrappers accept rectangular shapes, but this shared workload uses square matrices so each source returns compatible square `Q` and `R`; the square domain also avoids the C wrapper's extra uninitialized `R` rows. The Python Householder implementation omits the last reflector, which is sufficient for square input because the remaining trailing block is 1×1.

Malformed framing, unsupported bounds, fractional entries, any zero leading principal minor, or nonfinite property errors returns `-1` before output checks. A null output buffer or capacity below three returns `-2` without writes. The maximum valid input length is 17 values; one extra value is parseable so trailing data can be rejected. The output always contains three error norms.

## Pinned sources

- C wrapper [`qr_decomposition.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/numerical_methods/qr_decomposition.c), commit `e5dad3fa8def3726ec850ca66a7f51521f8ad393`; its algorithm helper is [`qr_decompose.h`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/numerical_methods/qr_decompose.h), symbol `qr_decompose`.
- C++ wrapper [`qr_decomposition.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/qr_decomposition.cpp), commit `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`; its algorithm helper is [`qr_decompose.h`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/qr_decompose.h), symbol `qr_algorithm::qr_decompose`.
- C++-1 wrapper [`qr_decomposition.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/numerical_methods/qr_decomposition.cpp), commit `0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680`.
- Python [`qr_decomposition.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/qr_decomposition.py), symbol `qr_householder`, pinned at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.
- Related Java modified Gram–Schmidt source [`QRDecomposition.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/matrix/QRDecomposition.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`qr_decomposition_oracle.py`](../../qr_decomposition_oracle.py)

## Ports

| Language | Port |
|---|---|
| C | [`c/q/qr_decomposition.c`](../../../c/q/qr_decomposition.c) |
| C3 | [`c3/q/qr_decomposition.c3`](../../../c3/q/qr_decomposition.c3) |
| C++ | [`cpp/q/qr_decomposition.cpp`](../../../cpp/q/qr_decomposition.cpp) |
| Elisa | [`elisa/q/qr_decomposition.elisa`](../../../elisa/q/qr_decomposition.elisa) |
| Nim | [`nim/q/qr_decomposition.nim`](../../../nim/q/qr_decomposition.nim) |
| Odin | [`odin/q/qr_decomposition.odin`](../../../odin/q/qr_decomposition.odin) |
| Rust | [`rust/q/qr_decomposition.rs`](../../../rust/q/qr_decomposition.rs) |
| V | [`v/q/qr_decomposition.v`](../../../v/q/qr_decomposition.v) |
| Zig | [`zig/q/qr_decomposition.zig`](../../../zig/q/qr_decomposition.zig) |
