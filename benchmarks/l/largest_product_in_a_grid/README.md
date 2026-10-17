# Largest product in a grid

Return the largest product of four adjacent cells in a rectangular grid, checking horizontal, vertical, down-right, and down-left directions. The generalized package is separate from the fixed canonical-grid Project Euler 11 solution.

## Contract

- The pinned JavaScript export is `largestProductInAGrid` at the source URL below.
- Input is a signed 64-bit integer array `[rows, cols, row_major_cells...]`, with exact length `2 + rows * cols`.
- Each dimension is in `[0, 63]`; each cell is in `[0, 1000]`. The maximum input length is 3,971 values.
- Each candidate is the product of exactly four adjacent cells. Out-of-bounds positions contribute zero, matching the pinned helper. The maximum starts at zero, so empty grids and nonnegative grids without a four-cell path return zero.
- The maximum candidate product is `1000^4 = 1,000,000,000,000`, exactly representable in JavaScript Number and within signed 64-bit range.
- Malformed input returns `-1`. Valid output is the scalar maximum.

## Pinned source

[TheAlgorithms/JavaScript Project-Euler/Problem011.js](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Project-Euler/Problem011.js)

## Workload and oracle

[workload.json](workload.json) covers empty dimensions, missing four-cell paths, each direction, the maximum product, maximum input size, and invalid dimensions, lengths, and values. The independent oracle is [largest_product_in_a_grid_oracle.py](../../largest_product_in_a_grid_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/l/largest_product_in_a_grid.c](../../../c/l/largest_product_in_a_grid.c) |
| C3 | [c3/l/largest_product_in_a_grid.c3](../../../c3/l/largest_product_in_a_grid.c3) |
| C++ | [cpp/l/largest_product_in_a_grid.cpp](../../../cpp/l/largest_product_in_a_grid.cpp) |
| Elisa | [elisa/l/largest_product_in_a_grid.elisa](../../../elisa/l/largest_product_in_a_grid.elisa) |
| Nim | [nim/l/largest_product_in_a_grid.nim](../../../nim/l/largest_product_in_a_grid.nim) |
| Odin | [odin/l/largest_product_in_a_grid.odin](../../../odin/l/largest_product_in_a_grid.odin) |
| Rust | [rust/l/largest_product_in_a_grid.rs](../../../rust/l/largest_product_in_a_grid.rs) |
| V | [v/l/largest_product_in_a_grid.v](../../../v/l/largest_product_in_a_grid.v) |
| Zig | [zig/l/largest_product_in_a_grid.zig](../../../zig/l/largest_product_in_a_grid.zig) |
