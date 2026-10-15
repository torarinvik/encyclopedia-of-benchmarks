# Minimum Cost Path

Return the minimum accumulated cell cost from the top-left to the bottom-right of a rectangular matrix, moving only right or down.

## Contract

- The `i64_array_scalar` ABI packs `[rows, columns, row-major cell values...]`.
- Rows and columns must each be in `1..=16`; the packed length must equal `2 + rows * columns`.
- Cells are signed 32-bit integers. Return the exact minimum path sum as signed 64-bit; malformed input returns `INT64_MIN`.
- Negative costs are supported. The supported bounds keep any possible path sum within signed 64-bit range.
- Accumulate the first row and column from their only predecessor, then scan row-major and update each cell by adding the smaller of its top and left costs. Ports use a local table because the ABI input is read-only.

## Source semantics

The canonical pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/minimum_cost_path.py) mutates its input while accumulating the first row, first column, and remaining cells. Its return value is the bottom-right accumulated cost. The mutation does not affect that result; this package retains the recurrence with a local table. The cataloged JavaScript sibling uses a separate DP table and the same right/down contract. This differs from minimum falling path sum, which also allows diagonal moves, and from path-counting algorithms.

The pinned Rust function uses `Vec<Vec<usize>>`, so its source domain contains nonnegative costs. The signed contract and negative-cost workload cases extend that behavior for Python, JavaScript, and the portable ports.

## Workload

[`workload.json`](workload.json) covers both pinned examples, single row/column grids, negative values, malformed lengths, and bounds.
