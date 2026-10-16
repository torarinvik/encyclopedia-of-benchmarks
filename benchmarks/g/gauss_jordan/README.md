# Gauss–Jordan reduction

This benchmark follows the pinned Python function, which reduces a coefficient matrix and its right-hand-side vector together. For each column it selects the first pivot that is not close to zero from the current row downward, swaps that row into place, normalizes the full pivot row, then eliminates the pivot column from every other row. Columns without a pivot are skipped. It returns both transformed arrays, including for rectangular and rank-deficient systems.

Input is `[row_count, column_count, row-major coefficients, rhs]`. Each dimension is 1–4, values are thousandths in [-5, 5], and the RHS has one value per row. Output concatenates the row-major reduced coefficients followed by the transformed RHS, serialized as little-endian binary64. Invalid inputs return -1; an output buffer smaller than the encoded result returns -2 without writing. The maximum output workspace is 160 bytes. Runtime oracle: `gauss_jordan_oracle.py`.
