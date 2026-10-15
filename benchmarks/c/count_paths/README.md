# Count paths in a grid

Counts vertex-simple paths from the upper-left cell to the lower-right cell in a grid with blocked cells. This package follows the pinned recursive depth-first search in TheAlgorithms Python.

## Contract

- Uses `i64_array_scalar` with packed input `[rows, columns, cells...]`; cells are row-major.
- Each dimension is from 1 through 5, and the grid has at most 25 cells. Cells must be `0` (open) or `1` (blocked).
- A path moves one cell down, up, right, or left. A cell cannot appear twice in one path. The DFS tries directions in that order and backtracks its visited marks.
- Returns the number of paths. An open 1×1 grid has one path; a blocked start or destination has none. Malformed dimensions, lengths, or cells return `-1`.
- The maximum simple-path count is bounded by `1 + 4(1 + 3 + ... + 3^23) = 564,859,072,961`, safely within signed 64-bit output.

The pinned Python routine blocks only cells equal to `1`; the benchmark restricts cells to binary values. Empty and ragged grids are outside the contract because the source indexes the first row and assumes rectangular input.

## Source and related algorithms

This package follows [TheAlgorithms Python `matrix/count_paths.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/count_paths.py). Its recursive function rejects out-of-bounds, blocked, and already-visited cells, returns one at the destination, then explores down, up, right, and left while marking and unmarking the current cell.

This differs from `unique_paths` and `unique_paths_with_obstacles`, which allow only right and down moves. It also differs from `number_of_paths`, which searches simple paths in a directed adjacency matrix.

## Workload

[`workload.json`](workload.json) includes the pinned 4×4 and 4×5 examples, small boundary cases, a narrow corridor, a maximum-size single-route grid, and malformed packed inputs. It uses 200 repetitions per sample because open-grid DFS grows quickly with the number of cells.
