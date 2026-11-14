# Histogram area through a Cartesian tree

Build a min Cartesian tree of the histogram using a monotone stack, then
compute each node's subtree size in postorder and maximize height times size.
This differs from [`largest_rectangle_histogram`](../../l/largest_rectangle_histogram/README.md),
which calculates areas directly as entries leave a monotone stack; it also
differs from [`cartesian_tree`](../cartesian_tree/README.md), which outputs the
tree rather than traversing it to calculate a histogram area.

The `i64_array_scalar` input consists of zero to 64 heights, each in
`0..1000000`. Return the maximum area, or `INT64_MIN` for an invalid height or
an overlength array. An empty array returns zero even when the input is null;
null with positive length is invalid. A stable leftmost minimum is used when
heights tie. Maximum valid area is 64000000. Construction and traversal each
take O(n) time and O(n) auxiliary space.

For a non-null input with a positive valid length, the caller supplies at
least that many readable heights. An overlength input is rejected before any
height is read. The maximum-length plateau in the workload exercises both the
64-element boundary and the largest valid result.

The [OI Wiki Cartesian-tree overview](https://en.oi-wiki.org/ds/cartesian-tree/)
describes the tree-based histogram approach. The local contract, implementation,
and reference are independently written; no external source or examples are
copied. Reserved for root: drafts in all ten languages, the independent
quadratic reference, workload, and scalar-suite registration are unverified.
No code has been run.
