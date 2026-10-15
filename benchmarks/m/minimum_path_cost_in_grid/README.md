# Minimum Path Cost in a Grid

Find the least-cost path from the top row to the bottom row. Each move adds the current cell value, the transition cost indexed by that value and the next column, and then the final cell value.

## Contract

- The benchmark packs input as `[rows, columns, grid row-major, move_cost row-major]`. The move-cost table has `rows * columns` rows and `columns` values per row.
- Rows and columns are each in `1..32`. Grid values are in `0..rows*columns-1`; move costs are in `1..100`.
- Invalid packed inputs return `-1`. Input is read only.
- Implementations keep only the current and next row of dynamic-programming costs. Time is O(rows * columns²); auxiliary space is O(columns).

## Workload and verification

[`workload.json`](workload.json) covers single-row and single-column grids, the source example, tied paths, varied movement costs, and a 32-by-8 grid. [`benchmarks/verify_minimum_path_cost_in_grid.py`](../../verify_minimum_path_cost_in_grid.py) checks all nine ports against an independent row-by-row path oracle, including exhaustive small instances, seeded grids, malformed inputs, and maximum supported dimensions.

## Upstream source

- [TheAlgorithms/C LeetCode 2304](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2304.c)
