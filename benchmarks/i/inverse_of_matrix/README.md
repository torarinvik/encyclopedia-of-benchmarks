# Inverse of a matrix

This benchmark compares the pinned Java scaled-pivot Gaussian elimination implementation with the pinned Python direct 2×2 and 3×3 determinant/cofactor implementation. Both return the row-major inverse matrix.

## Contract

The ABI is i64_array_bytes_output. Input is [n, q00, q01, ..., q(n-1)(n-1)], with row-major signed-i64 coefficients. The matrix dimension is 2 or 3, and each coefficient q represents the exact binary64 value q/16, with q in [-32, 32]. A valid matrix has exactly one strictly dominant coefficient in every row: for that column j, abs(q[i][j]) is greater than the sum of the absolute values of the other row entries. These dominant columns must be distinct across rows. Reordering rows by dominant column gives a strictly row-diagonally-dominant matrix, so every accepted matrix is finite and nonsingular with safe pivots.

Malformed framing, an unsupported dimension, an out-of-range coefficient, or a matrix outside this shared stable domain returns -1. The Java source mutates its matrix argument, so each port works on its local decoded matrix. For valid input, a null or undersized output buffer returns -2; success returns the number of output bytes. Validation happens before output-buffer checks, and errors leave the output buffer untouched.

The output is the complete inverse in row-major order, encoded as little-endian IEEE-754 binary64 values. The maximum output is 9 values or 72 bytes. Every inverse coefficient has absolute value at most 32,768: for the q/16 grid, the nonzero integer determinant has magnitude at least 1, while 3×3 integer cofactors have magnitude at most 2×32×32. Results use absolute tolerance 1e-9 and relative tolerance 1e-12 to cover the Java elimination and Python Decimal calculation paths.

## Pinned sources

- Java InverseOfMatrix.invert: https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/matrix/InverseOfMatrix.java
- Python inverse_of_matrix: https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/inverse_of_matrix.py

## Workload and oracle

The workload covers identity, row-pivoting, triangular, signed, and full 3×3 inverses, plus malformed, singular, and outside-domain matrices. The independent oracle uses exact integer determinants and cofactors over the q/16 coefficients, converts the exact rational inverse to binary64, and serializes it in row-major little-endian order.

- Workload: workload.json
- Oracle: ../../inverse_of_matrix_oracle.py

## Ports

The nine local ports use Java's scaled-pivot Gaussian elimination method.

| Language | Source |
| --- | --- |
| C | [`c/i/inverse_of_matrix.c`](../../../c/i/inverse_of_matrix.c) |
| C3 | [`c3/i/inverse_of_matrix.c3`](../../../c3/i/inverse_of_matrix.c3) |
| C++ | [`cpp/i/inverse_of_matrix.cpp`](../../../cpp/i/inverse_of_matrix.cpp) |
| Elisa | [`elisa/i/inverse_of_matrix.elisa`](../../../elisa/i/inverse_of_matrix.elisa) |
| Nim | [`nim/i/inverse_of_matrix.nim`](../../../nim/i/inverse_of_matrix.nim) |
| Odin | [`odin/i/inverse_of_matrix.odin`](../../../odin/i/inverse_of_matrix.odin) |
| Rust | [`rust/i/inverse_of_matrix.rs`](../../../rust/i/inverse_of_matrix.rs) |
| V | [`v/i/inverse_of_matrix.v`](../../../v/i/inverse_of_matrix.v) |
| Zig | [`zig/i/inverse_of_matrix.zig`](../../../zig/i/inverse_of_matrix.zig) |

