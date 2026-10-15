# Sudoku solver

Fill a 9×9 Sudoku board so each row, column, and 3×3 box contains digits 1 through 9 exactly once. The search scans cells in row-major order and tries digits from 1 through 9, matching the intended backtracking order of the upstream routine.

## Contract

- Input is exactly 81 signed 64-bit cells in row-major order. `0` means blank; clues are from 1 through 9.
- Clues may not repeat in any row, column, or 3×3 box. A valid puzzle has exactly one solution.
- Return `81` and write the solved board in row-major order as signed 32-bit little-endian cells. The input remains unchanged.
- Invalid dimensions, cell values, or conflicting clues return `-1`; insufficient output capacity returns `-2`.
- Implementations keep row, column, and box occupancy masks and use recursive backtracking. They write a trial digit before searching the next cell and restore the cell and masks when that choice fails.

## Workload and verification

[`workload.json`](workload.json) includes a standard puzzle, a solved board, puzzles with a few blanks, a digit-permuted puzzle, and malformed boards. [`benchmarks/verify_sudoku_solver.py`](../../verify_sudoku_solver.py) checks the ports against an independent minimum-remaining-values solver, confirms puzzle uniqueness, and checks deterministic puzzle variants and the published workload.

The benchmark is based on [TheAlgorithms C LeetCode source `37.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/37.c). That source has a backtracking call-order bug: it updates occupancy sets, recurses, and only writes the trial digit to the board after recursion returns. The next call therefore encounters the same blank cell. These ports use the intended solver behavior by placing the digit before recursion and undoing it on failure.

Build with the shared `i64_array_bytes_output` ABI family and record with `benchmarks/run_i64_array_bytes_output.py`.
