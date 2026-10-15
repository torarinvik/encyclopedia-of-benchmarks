# Count islands in a matrix

Counts the number of connected land components in a rectangular binary matrix. This package follows the pinned recursive flood fill in TheAlgorithms Python, where diagonal neighbors connect an island.

## Contract

- Uses `i64_array_scalar` with packed input `[rows, columns, row-major cells...]`.
- Rows and columns are each from 1 through 16, and the matrix contains at most 256 cells. Every cell must be `0` (water) or `1` (land).
- Two land cells are connected when they share an edge or a corner. The result is the number of components, from 0 through 64. Malformed dimensions, lengths, or cell values return `-1`.
- The bounded binary input makes the source's truthy scan and `cell == 1` flood-fill check equivalent. Empty and ragged matrices are outside the contract; the source indexes the first row and assumes a rectangular matrix.

## Source and related algorithms

This package follows [TheAlgorithms Python `matrix/count_islands_in_matrix.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/count_islands_in_matrix.py). It scans cells row-major, increments the count at each unvisited land cell, then recursively marks all reachable land using the eight surrounding offsets.

This differs from `number_of_islands`, which uses four-directional connectivity, and from `area_of_island` and `max_area_of_island`, which return the largest component's area rather than the component count.

## Workload

[`workload.json`](workload.json) covers diagonal links, edge-only links, isolated cells, all-water and all-land matrices, the pinned examples, and malformed packed arrays. The largest workload matrix is 16×16.
