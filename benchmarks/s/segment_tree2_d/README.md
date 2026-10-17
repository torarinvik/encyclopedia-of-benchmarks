# Two-dimensional segment-tree trace

This benchmark follows the pinned Java 2D segment tree. It starts with a
zero-filled grid, applies point assignments and half-open submatrix-sum
queries, and returns a weighted checksum of query results.

## Contract

The `i64_array_scalar` input is
`[rows, columns, operation_count, (opcode, a, b, c, d) * operation_count]`.
Both dimensions are 1 through 16, cell values are -1,000 through 1,000, and
there are at most 256 operations. Every cell starts at zero.

Each operation contains four payload integers:

- `0, row, column, value, 0`: assign `value` to the cell; the final zero is
  reserved and required
- `1, top, bottom, left, right`: return the sum over rows
  `[top, bottom)` and columns `[left, right)`

Point coordinates must be inside the grid. Query bounds must satisfy
`0 <= top <= bottom <= rows` and `0 <= left <= right <= columns`. Empty
rectangles return zero. Unknown opcodes, out-of-range cells or values, invalid
bounds, a nonzero reserved field, truncated records, or trailing values return
`-1`.

For each query result `r` at zero-based operation position `i`, the checksum
adds `(i + 1) * (r + 256,001)`. Point assignments have no result contribution,
but still affect the positions of later queries. Since the largest possible
absolute rectangle sum is 256,000, every valid query contributes a positive
amount and the checksum cannot collide with invalid result `-1`. Cell and
intermediate sums also fit in the Java source's signed 32-bit `int`. The
maximum valid frame contains 1,283 integers; the maximum parseable frame
contains 1,284.

The source pads each dimension to a power of two internally. This contract
keeps all public updates and queries inside the requested grid, so the padded
cells remain zero and are not directly addressable. The nested tree stores
column segment trees at each row-tree node; updates assign a leaf and refresh
the corresponding row and column sums.

## Pinned source

- TheAlgorithms/Java [`SegmentTree2D.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/SegmentTree2D.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`

## Workload

The workload is [`workload.json`](workload.json); the independent matrix
oracle is [`benchmarks/segment_tree2_d_oracle.py`](../../segment_tree2_d_oracle.py).
