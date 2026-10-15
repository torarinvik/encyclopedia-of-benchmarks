# Unique Paths II

Count the paths from the top-left cell to the bottom-right cell of a grid when moves go only right or down and cells marked 1 are blocked.

## Contract

- Input is a packed array: rows, columns, then row-major cells.
- Accept 1 to 20 rows and columns. Each cell must be 0 or 1; invalid dimensions, lengths, or cell values return -1.
- Return the number of paths as a signed 64-bit integer. The 20 by 20 bound keeps the maximum obstacle-free count within signed 64-bit range.
- The ports compress the source's two-dimensional dynamic-programming table into one row. They take O(rows × columns) time and O(columns) auxiliary space.

The official problem uses grids up to 100 by 100 and guarantees answers at most 2,000,000,000. This benchmark narrows the grid dimensions, packs the input for the shared array-scalar ABI, and extends the result to 64-bit counts.

## Workload and verification

[workload.json](workload.json) includes the published examples, single-cell grids, blocked endpoints, unreachable destinations, invalid packed inputs, and the largest supported open grid. [benchmarks/verify_unique_paths_with_obstacles.py](../../verify_unique_paths_with_obstacles.py) checks all nine ports against an independent memoized path oracle using exhaustive small grids and seeded random grids.

Run the command: python3 benchmarks/verify_unique_paths_with_obstacles.py --elisa-compiler /absolute/path/to/elisac.

## Reviewed source

- [TheAlgorithms/C LeetCode 63 source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/63.c) and the [LeetCode problem statement](https://leetcode.com/problems/unique-paths-ii/)
