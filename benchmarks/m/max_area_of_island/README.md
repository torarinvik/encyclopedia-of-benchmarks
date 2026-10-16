# Maximum Area of Island

Return the size of the largest four-directionally connected island in a binary grid.

## Source

This package follows the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/max_area_of_island.py). The source scans cells in row-major order, starts a recursive depth-first search for each unseen land cell, marks reached land as seen, and returns the largest component size. Only up, down, left, and right neighbors connect; a cell is land exactly when it equals `1`.

## Contract

- ABI: `i64_array_scalar`, with packed input `[rows, columns, row-major cells...]`.
- Each dimension is in `0..=16`. The input contains exactly `2 + rows * columns` signed 64-bit integers, and every cell is `0` (water) or `1` (land).
- A zero-sized dimension returns `0`; malformed dimensions, length, or cell values return `-1`.
- The result is the largest four-connected land component, or `0` when there is no land. Ports use an explicit stack and visited map, preserving the recursive source result while bounding storage to 256 cells.

## Workload and oracle

[`workload.json`](workload.json) includes the pinned 8×13 example, diagonal separation, row-boundary behavior, empty shapes, single-cell cases, a full 16×16 island, and malformed inputs. The independent breadth-first oracle is [`max_area_of_island_oracle.py`](../../max_area_of_island_oracle.py). The nine ports export `max_area_of_island` using the shared `i64_array_scalar` runner.
