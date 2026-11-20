# Priority search tree: three-sided reporting

This bounded profile builds McCreight's radix priority search tree and answers
three-sided reporting queries. A query reports labeled points satisfying
`x0 <= x <= x1` and `y <= y1`. The tree uses an x-ordered radix split and a
min-y heap invariant. It is a different structure and query kernel from the
local four-sided range-tree profile [orthogonal_range_reporting_2d](../../o/orthogonal_range_reporting_2d/README.md).

## Contract

- Exported symbol: `priority_search_tree_three_sided_reporting`; ABI: `i64_array_scalar`.
- Input: `[N,Q,(x,y,label)*N,(x0,x1,y1)*Q]` with `0 <= N <= 8`,
  `0 <= Q <= 7`, `x in 0..31`, `y in -64..63`, and `label in 0..7`.
- Point x-coordinates and labels are each unique. Queries use closed x
  intervals and an inclusive y upper bound: `0 <= x0 <= x1 <= 31` and
  `-64 <= y1 <= 63`.
- The exact input length is `2 + 3*N + 3*Q`; maximum valid and parseable
  lengths are 47 and 48 words. Invalid or null input returns `-1`.
- For each query, output the 8-bit mask of reported labels. Pack query masks
  into consecutive result bytes in query order. Since `Q <= 7`, every mask is
  preserved without collisions in a nonnegative signed 64-bit scalar; the
  maximum is `2^56 - 1`.

## Radix priority search tree

This profile pins the paper's Section 2 radix priority search tree with root
x-interval `[0,32)`. Points arrive in input order. Each node stores one point
and a fixed half-open x-interval. To insert a point, compare its y-coordinate
with the node's: a strictly smaller y displaces the current point to be
inserted below; equal y does not displace it. Split the interval at its
midpoint and descend left or right according to the displaced point's x.
Thus each parent has y less than or equal to either child's y, while the
children occupy the left and right x halves.

For a query, traverse the tree depth first. Skip a subtree if its x interval
does not intersect `[x0,x1]` or its stored y-minimum exceeds `y1`. Otherwise,
report the node's label when its point satisfies the query, then visit its
children. The source gives `O(log k + s)` enumeration for the radix tree, with
`k` the x-domain size and `s` the number of reported points. This bounded call
builds from scratch using at most eight points and a 32-value x-domain.

The primary oracle uses the radix insertion and heap-pruned query. The
independent oracle scans all input points for each query and builds each label
mask directly. The packed result preserves every query's mask, rather than
only its hit count.

## Distinction and provenance

The local [four-sided range-reporting package](../../o/orthogonal_range_reporting_2d/README.md)
builds a balanced segment tree over x ranks and y-sorted catalogs, then answers
closed rectangles with both x and y lower and upper bounds. This package
instead uses McCreight's linear-space x-radix/y-priority structure and a
three-sided query with only an upper y bound.

Primary source: Edward M. McCreight, [“Priority Search Trees”](https://doi.org/10.1137/0214021),
*SIAM Journal on Computing* 14(2), 1985, Section 2. The paper specifies the
unique-x radix variant, its y-priority and x-interval invariants, and the
three-sided enumeration procedure. Only the algorithm description is used;
the profile and implementations are independently authored. See
[RIGHTS.md](RIGHTS.md).

## Ports and package files

[C](../../../c/p/priority_search_tree_three_sided_reporting.c) ·
[C3](../../../c3/p/priority_search_tree_three_sided_reporting.c3) ·
[C++](../../../cpp/p/priority_search_tree_three_sided_reporting.cpp) ·
[Elisa](../../../elisa/p/priority_search_tree_three_sided_reporting.elisa) ·
[Mojo](../../../mojo/p/priority_search_tree_three_sided_reporting.mojo) ·
[Nim](../../../nim/p/priority_search_tree_three_sided_reporting.nim) ·
[Odin](../../../odin/p/priority_search_tree_three_sided_reporting.odin) ·
[Rust](../../../rust/p/priority_search_tree_three_sided_reporting.rs) ·
[V](../../../v/p/priority_search_tree_three_sided_reporting.v) ·
[Zig](../../../zig/p/priority_search_tree_three_sided_reporting.zig)

Fixtures: [workload.json](workload.json). References:
[primary_oracle.py](primary_oracle.py) and
[independent_oracle.py](independent_oracle.py). Static package inventory:
[verify_workload.py](verify_workload.py).
