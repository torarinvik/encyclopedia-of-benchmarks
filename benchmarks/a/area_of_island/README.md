# Area of Island

Return the size of the largest four-directionally connected land region in a rectangular grid. The benchmark packs the grid into a signed 64-bit array in row-major order.

## Contract

- Input is `[rows, columns, cell_0, cell_1, ...]`, with cells in row-major order.
- Rows must be in `1..64`, columns in `0..64`, and the array must contain exactly `2 + rows * columns` values. A zero-width grid returns `0`; zero rows and other malformed inputs return `-1`.
- A cell equal to zero is water. Every nonzero signed 64-bit value is land, matching the source's `grid[i][j] == 0` water check.
- Only up, right, down, and left neighbors connect. Diagonal contact does not connect cells.
- The result is the maximum connected land-cell count, or `0` when there is no land. The input is read only; the maximum result is 4,096.
- The implementation uses iterative depth-first search with `O(rows * columns)` time and auxiliary space.

## Upstream source

The pinned Dart source is [`graphs/area_of_island.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/graphs/area_of_island.dart). `maxAreaOfIsland` walks each unvisited nonzero cell, explores its four orthogonal neighbors with an explicit stack, counts each component, and returns the largest count (zero when no cells are land). It assumes at least one row and a rectangular grid; the packed benchmark contract makes that shape explicit and returns `-1` for zero rows, invalid dimensions, or a mismatched cell count. It preserves the source's zero-width result of zero.

## Implementations and workload

All nine ports use the `i64_array_scalar` ABI in `c/`, `c3/`, `cpp/`, `elisa/`, `nim/`, `odin/`, `rust/`, `v/`, and `zig/`. [`workload.json`](workload.json) includes the three published examples, diagonal separation, nonbinary nonzero land values, signed boundaries, maximum-size grids, and malformed packed inputs.

Build and record with `python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm area_of_island --language LANGUAGE` and `python3 benchmarks/run_i64_array_scalar.py`.
