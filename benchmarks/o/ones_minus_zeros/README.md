# Difference Between Ones and Zeros in Row and Column

This benchmark is based on C LeetCode candidate [2482](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2482.c). Its canonical benchmark name is `ones_minus_zeros`.

## Contract

The input is a signed 64-bit array containing `[rows, columns, cells...]`, with the cells in row-major order. Rows and columns must each be from 1 through 100,000, the matrix may contain at most 100,000 cells, and each cell must be 0 or 1. Invalid input returns `-1`.

For each cell `(r, c)`, the output is:

```text
onesRow[r] + onesColumn[c] - zerosRow[r] - zerosColumn[c]
```

The result is written in row-major order as signed 32-bit little-endian two's-complement values. Calls supply valid non-null input and output pointers. A valid call returns the cell count. If the output capacity is less than four bytes per cell, the function returns `-2` before writing any bytes.

## Implementation

All nine ports use portable scalar operations without processor-specific intrinsics. They run in `O(rows * columns)` time and use the caller's output buffer to hold row and column counts temporarily, so they need no dimension-sized auxiliary arrays. Rows are finalized from bottom to top while column counts remain available; row zero is finalized last.

The pinned upstream C source uses the opposite dimension when deriving zero counts on rectangular matrices (`rows - onesInRow` for row zeros and `columns - onesInColumn` for column zeros). This benchmark follows the stated row/column formula above, which is also exercised with non-square matrices.

## Workload and verification

The published workload includes small correctness cases and a 100 by 1,000 matrix at the full 100,000-cell limit. The verifier compares the complete output bytes against an independent row/column-count oracle, checks malformed inputs and insufficient output capacity, and records the workload through the shared byte-output runner.
