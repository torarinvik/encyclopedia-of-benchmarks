# Dynamic centroid active-set diameter

This bounded profile toggles vertices in a fixed unit-edge tree and queries
the diameter of the currently active set. It uses a centroid decomposition;
each vertex stores its centroid ancestors, branch IDs, and distances. Every
centroid/branch bucket keeps the largest active distance, and a diameter
candidate combines the two largest values from distinct branches. The
centroid itself occupies a separate branch, including at distance zero.

## Contract

- ABI: `i64_array_scalar`.
- Input is `[n, q, parent[1], ..., parent[n-1], op[0], ..., op[q-1]]`.
  Vertex 0 is the root, and `0 <= parent[v] < v` for each `v > 0`.
- `1 <= n <= 32`, `0 <= q <= 64`, and the exact input length is `n + 1 + q`.
  Each operation is `-1` to query or a vertex ID in `[0,n)` to toggle that
  vertex's active state. All vertices start inactive.
- A query returns the largest unit-edge distance between any two active
  vertices. It returns zero when fewer than two vertices are active.
- The scalar result is the checksum
  `sum(query_number * (diameter + 1))`, where query numbers start at one and
  count only query operations. It is zero when the operation stream has no
  query. Malformed or null input returns `-1`.
- The maximum valid input length is 97 i64 values; the maximum parseable
  length is 98. The checksum is at most 66,560 and fits signed 64-bit.

The primary reference follows centroid decomposition and maintains the
per-centroid/per-branch active-distance maxima. A bounded scan recomputes a
bucket after deleting its current maximum. The independent reference computes
all-pairs tree distances directly and scans active pairs on each query. This
profile keeps the tree fixed and does not include edge or vertex insertions.
Each vertex has at most six centroid-ancestor records. The bounded ports use
`O(n^2)` adjacency and branch-bucket storage; a query scans all centroid
buckets, and deletion of a bucket maximum rescans active vertex records for
that bucket.

## Reference

[OI Wiki: Dynamic Tree Divide and Conquer](https://www.timothywang.ca/OI-wiki/graph/dynamic-tree-divide/)
describes the centroid-decomposition hierarchy, ancestor distance records,
and dynamic active-set diameter example. This package uses the page for the
algorithm idea only. The operation encoding, bounded contract, references,
fixtures, prose, and ten language ports are independently written. See
[RIGHTS.md](RIGHTS.md), [workload.json](workload.json), and
[INVENTORY.md](INVENTORY.md).
