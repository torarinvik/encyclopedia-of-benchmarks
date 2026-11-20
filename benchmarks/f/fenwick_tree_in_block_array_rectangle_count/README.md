# Fenwick Tree in Block Array: online rectangle counts

Maintain one point for each x-coordinate while processing point-y updates and
online rectangle-count queries. The final result is a weighted checksum of
the answers, so every query contributes to one scalar return value.

## Contract

- Input is `[n, q, y[0..n-1], op0[5], ..., op(q-1)[5]]`, where
  `1 <= n <= 24`, `1 <= q <= 32`, and each initial y-coordinate is in
  `[0,n)`. The x-coordinate of `y[x]` is its array index.
- An update is `[0, x, new_y, 0, 0]`, with `0 <= x < n` and
  `0 <= new_y < n`.
- A query is `[1, x_left, x_right, y_low, y_high]` and counts current points
  in `[x_left,x_right) x [y_low,y_high)`. Bounds are in `[0,n]` and each
  lower bound must not exceed its upper bound. Empty rectangles are valid.
- If the query counts are `c_1, c_2, ...` in query order, return
  `sum(j * c_j)` using one-based query ordinal `j`. Malformed or null input
  returns `-1`.
- The primary port partitions x into blocks of size `ceil(sqrt(n))`. Every
  outer Fenwick node stores an inner Fenwick tree over y values. A point update
  changes the inner y trees along its outer Fenwick path. A two-dimensional
  prefix count scans the final partial x-block and queries complete blocks
  through the outer Fenwick tree; four prefix counts form each rectangle.
  With `B = ceil(sqrt(n))`, the structure uses `O(nB)` space, updates take
  `O(log(B+1) log(n+1))`, and rectangle queries take
  `O(B + log(B+1) log(n+1))` time.
- The independent reference scans all n points for each query. The bounded
  limits keep both methods small while preserving their different work
  patterns. The maximum valid input has 186 signed values; the parser accepts
  up to one trailing value so malformed framing is also covered.

The profile follows the blocked Fenwick method described by [OI Wiki](https://www.timothywang.ca/OI-wiki/ds/bit-in-block-array/).
See [RIGHTS.md](RIGHTS.md) for provenance. The package's ten source ports and
references are catalogued in [INVENTORY.md](INVENTORY.md); shared suite wiring
is handled separately.

## Language ports

- [C](../../../c/f/fenwick_tree_in_block_array_rectangle_count.c)
- [C3](../../../c3/f/fenwick_tree_in_block_array_rectangle_count.c3)
- [C++](../../../cpp/f/fenwick_tree_in_block_array_rectangle_count.cpp)
- [Elisa](../../../elisa/f/fenwick_tree_in_block_array_rectangle_count.elisa)
- [Mojo](../../../mojo/f/fenwick_tree_in_block_array_rectangle_count.mojo)
- [Nim](../../../nim/f/fenwick_tree_in_block_array_rectangle_count.nim)
- [Odin](../../../odin/f/fenwick_tree_in_block_array_rectangle_count.odin)
- [Rust](../../../rust/f/fenwick_tree_in_block_array_rectangle_count.rs)
- [V](../../../v/f/fenwick_tree_in_block_array_rectangle_count.v)
- [Zig](../../../zig/f/fenwick_tree_in_block_array_rectangle_count.zig)
