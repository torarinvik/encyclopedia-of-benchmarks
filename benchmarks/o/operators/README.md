# Matrix operators

This benchmark ports the pinned Clojure `operators.clj` elementwise `add` and `sub` functions, which share the `item-by-item` helper. The selector is 0 for addition and 1 for subtraction. Input is `[operation, rows_a, columns_a, A row-major values..., rows_b, columns_b, B row-major values...]`. Matrices have 1–16 rows and 0–16 columns, at most 256 elements, and values in `[-1,000,000, 1,000,000]`; these bounds keep results in signed i32. Matching shapes return row-major little-endian signed i32 values. Shape mismatch maps the source's `nil` result to -1. Empty-row matrices are excluded because the source's `get-dimensions` reads the first row; positive-row zero-column matrices are supported.

The runtime oracle is `operators_oracle.py`.
