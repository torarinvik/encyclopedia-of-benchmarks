# Dancing Links (Algorithm X)

Find every exact cover of a small binary matrix using Algorithm X's smallest-column search. This is a general exact-cover problem, distinct from the repository's Sudoku solvers, which only cover Sudoku's fixed constraint matrix.

## Contract

Input is `[universe_size, row_count, row_mask_0, ...]`. `universe_size` is 1 through 8, `row_count` is 0 through 8, and each row mask is nonzero and contains only universe columns. Rows are indexed, so repeated masks represent distinct choices. The input length must be `row_count + 2`.

Return the number of exact-cover row selections. Emit each solution as one byte where bit `i` selects row `i`; sort these bytes in ascending numeric order. Invalid input returns `-1`. Insufficient output capacity returns `-2` without writing.

## Reviewed source

The pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/dancing_links.py) builds linked row and column nodes, chooses the remaining column with the fewest rows, and recursively covers and uncovers columns to enumerate all solutions. Its public interface takes a universe and subsets. This package preserves that general Algorithm X behavior while using bounded bitmasks and a deterministic serialized result.

## Workload and implementations

[`workload.json`](workload.json) contains satisfiable, unsatisfiable, duplicate-row, and invalid matrices. [`benchmarks/verify_dancing_links.py`](../../verify_dancing_links.py) checks all nine ports against a deterministic bounded corpus and verifies output-capacity handling. All ports use the shared i64-array/bytes-output ABI.
