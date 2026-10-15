# Number of islands

Counts land components in a rectangular binary matrix with four-directional connectivity. This follows the recursive flood-fill behavior in the pinned JavaScript and Ruby implementations.

## Contract

- ABI: `i64_array_scalar`, packed input `[rows, columns, row-major cells...]`.
- `rows` and `columns` are each in `1..=16`; every cell is `0` (water) or `1` (land). The packed array must contain exactly `2 + rows * columns` values.
- Cells are connected only when they share an edge. The output is the number of connected land components. Invalid dimensions, length, or cell values return `-1`.
- The limit of 256 cells bounds recursive flood-fill depth. Ports use a visited map rather than mutating the input matrix; this preserves the observable component count.

## Source and related algorithms

The package is grounded in [TheAlgorithms JavaScript `NumberOfIslands.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Graphs/NumberOfIslands.js) and [TheAlgorithms Ruby `number_of_islands.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/searches/number_of_islands.rb). Both use four-neighbor recursive flood fill and mark reached land as visited. Their neighbor visitation order differs, but the component count is invariant.

This differs from [`count_islands_in_matrix`](../../c/count_islands_in_matrix/README.md), which joins diagonal neighbors, and from `area_of_island` / `max_area_of_island`, which report the largest component's area.

## Workload

[`workload.json`](workload.json) covers edge-connected groups, diagonal-only separation, isolated land cells, water and land matrices, a single-cell matrix, and malformed packed arrays. The largest matrix is 16×16.
