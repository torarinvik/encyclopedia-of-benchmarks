# Two-dimensional KD-tree trace

This benchmark follows the median-built and insertable KD-tree in the pinned
Java source. It builds a tree from an optional initial point set, applies a
bounded sequence of insert and query operations, and returns a weighted scalar
checksum.

## Contract

The `i64_array_scalar` input is
`[initial_count, (x, y) * initial_count, operation_count, (opcode, a, b) * operation_count]`.
There are at most 64 initial points, 128 points in the tree after inserts, and
256 operations. The tree has exactly two dimensions. Coordinates are integers
from -1,000 through 1,000 inclusive. To keep the source's median partitions
searchable and its coordinate tie behavior deterministic, all stored points
must have distinct x coordinates and distinct y coordinates. A duplicate
stored x or y makes the entire input invalid.

Operation records always contain three integers:

- `0, x, y`: insert the point; it contributes no query result
- `1, x, y`: exact search; observe 1 if the point is found and 0 otherwise
- `2, axis, 0`: report the minimum stored coordinate on axis 0 or 1
- `3, axis, 0`: report the maximum stored coordinate on axis 0 or 1
- `4, x, y`: report the squared Euclidean distance to the point returned by
  the pinned `findNearest` traversal

Insertions that exceed the point limit or reuse a stored x or y coordinate are
invalid. Search on an empty tree returns 0. Minimum, maximum, and nearest-point
queries require a nonempty tree; otherwise the input is invalid. Coordinates
and axes outside the stated domains, a nonzero reserved field, unknown opcodes,
truncated records, or trailing values return `-1`.

For each query result `r` at zero-based operation position `i`, the checksum
adds `(i + 1) * (r + 1,001)`. Thus the checksum stays nonnegative and cannot
collide with the invalid result `-1`. Insert operations still affect the
one-based positions of later query results. The maximum valid frame contains
898 integers; the maximum parseable frame contains 899 integers.

The initial tree uses the source's median split: sort points by the current
axis, choose index `count >> 1`, and recurse on the points before and after
that median while alternating axes. Subsequent insertions descend by the node's
axis and send equal coordinates to the right. Stored-coordinate uniqueness
avoids equal-axis ties in valid trees. Nearest queries follow the source's
recursive traversal exactly and expose the returned point's squared distance,
not its coordinates. The pinned source has a pruning quirk: it compares the
current best full squared distance with the distance that excludes the
splitting axis before visiting the far child. In two dimensions this uses the
other-axis difference instead of the distance to the splitting plane, so it
can skip a closer point. The workload covers a trace where this returns
squared distance 2,501 even though another stored point is at squared distance
4; ports must preserve this source behavior rather than replace it with a
global nearest-point scan.

## Pinned source

- TheAlgorithms/Java [`KDTree.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/KDTree.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`

## Workload

The workload is [`workload.json`](workload.json); the independent operation
oracle is [`benchmarks/kdtree_oracle.py`](../../kdtree_oracle.py).
