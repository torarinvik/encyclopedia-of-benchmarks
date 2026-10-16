# Linear recurrence by matrix exponentiation

This package benchmarks the pinned C++ routine that raises a square transition matrix to a power and multiplies it by an initial row vector. It supports general linear recurrences, constant terms, and recurrence sums; it is not limited to Fibonacci numbers.

## Contract

- The `i64_array_scalar` input is `[d, n, constant_or_sum_included, matrix_row_major(d*d), base_row(d)]`.
- The matrix dimension `d` is 1–4, and `n` is 0–1,000,000. The transition matrix and base row are row-major values in `[0, 1,000,000,006]`; the source's default modulus is fixed at `1,000,000,007`.
- `constant_or_sum_included` is 0 or 1 and selects the same offset behavior as the source's Boolean parameter. When it is 1, require `n >= d - 1`; smaller inputs would underflow the source's unsigned base-case index.
- A zero transition matrix is valid. For terms beyond the supplied base row, the source's zero-matrix shortcut returns a zero matrix, so the resulting term is zero.
- Invalid lengths, dimensions, selectors, indices, or matrix/base values return `-1`.
- The 24-element parse cap admits one extra value past the largest valid `d=4` input so malformed length can be checked by the function.

All modular products stay within signed 64-bit range for the chosen nonnegative residue domain. [`workload.json`](workload.json) includes the source's Fibonacci, Tribonacci, Pell, constant-recurrence, Fibonacci-sum, and Tribonacci-sum examples, plus base-case, zero-matrix, modulus-boundary, and invalid-input cases. The independent oracle is [`linear_recurrence_matrix_oracle.py`](../../linear_recurrence_matrix_oracle.py).

## Pinned source

- [TheAlgorithms/C-Plus-Plus `math/linear_recurrence_matrix.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/linear_recurrence_matrix.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `math/linear_recurrence_matrix.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/linear_recurrence_matrix.cpp)

The algorithm and examples match at both pins; the C-Plus-Plus-1 copy omits the explicit `<cstdint>` include found in the other copy.

## Verification

All nine ports passed 588 oracle arrays each and recorded all 36 workload cases with `verify_i64_array_scalar.py`.

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/l/linear_recurrence_matrix.c`](../../../c/l/linear_recurrence_matrix.c) |
| C3 | [`c3/l/linear_recurrence_matrix.c3`](../../../c3/l/linear_recurrence_matrix.c3) |
| C++ | [`cpp/l/linear_recurrence_matrix.cpp`](../../../cpp/l/linear_recurrence_matrix.cpp) |
| Elisa | [`elisa/l/linear_recurrence_matrix.elisa`](../../../elisa/l/linear_recurrence_matrix.elisa) |
| Nim | [`nim/l/linear_recurrence_matrix.nim`](../../../nim/l/linear_recurrence_matrix.nim) |
| Odin | [`odin/l/linear_recurrence_matrix.odin`](../../../odin/l/linear_recurrence_matrix.odin) |
| Rust | [`rust/l/linear_recurrence_matrix.rs`](../../../rust/l/linear_recurrence_matrix.rs) |
| V | [`v/l/linear_recurrence_matrix.v`](../../../v/l/linear_recurrence_matrix.v) |
| Zig | [`zig/l/linear_recurrence_matrix.zig`](../../../zig/l/linear_recurrence_matrix.zig) |
