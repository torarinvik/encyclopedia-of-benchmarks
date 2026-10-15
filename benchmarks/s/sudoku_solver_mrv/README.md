# Sudoku Solver with Constraint Propagation and MRV

This benchmark preserves Peter Norvig's solver strategy from TheAlgorithms/Python: maintain candidate digits per cell, propagate naked and hidden singles, then search the unresolved cell with the fewest candidates (minimum remaining values, or MRV). Each branch copies the candidate state before trying the next digit.

## Contract

- Input is exactly 81 signed 64-bit cells in row-major order. `0` means blank; clues are from 1 through 9.
- Clues may not repeat in any row, column, or 3×3 box. Inputs in the workload have one solution.
- Return `81` and write one solved board in row-major order as signed 32-bit little-endian cells. The input remains unchanged.
- Invalid dimensions, cell values, conflicting clues, or an unsolvable board return `-1`. Insufficient output capacity returns `-2` without writing.
- The search uses constraint propagation and MRV selection, rather than the sibling benchmark's row-major cell scan.

[`workload.json`](workload.json) uses the same unique puzzle corpus as [`sudoku_solver`](../sudoku_solver/README.md), allowing direct comparison of the two search strategies.

Build with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm sudoku_solver_mrv --language rust
```

## Upstream reference

- [TheAlgorithms/Python `sudoku_solver.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/sudoku_solver.py)
