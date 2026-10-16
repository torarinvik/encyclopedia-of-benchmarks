# Gaussian elimination with pivoting

This benchmark follows the pinned Python solver's executable pivot and elimination order. At each column it selects the largest absolute pivot from the current row downward, retaining the first row on ties, checks the pivot against `1e-8`, then eliminates using the previous pivot row. This source performs that elimination after choosing the next pivot. It finishes with backward substitution and updates the right-hand side in descending row order.

Input is `[dimension, row-major augmented matrix]`, where each row contains its coefficients followed by the right-hand side. Dimension is 2–4, values are thousandths in [-10, 10], and a pivot below `1e-8` returns -1. Output is the solution vector as little-endian binary64. The contract excludes NumPy shape handling and console examples. Runtime oracle: `gaussian_elimination_pivoting_oracle.py`.
