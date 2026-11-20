# Reverse Cuthill–McKee ordering

This bounded simple-graph profile constructs degree-ordered Cuthill–McKee
breadth-first traversals, concatenates components in root-discovery order,
reverses the complete sequence, and reports its graph bandwidth. Component
roots are the minimum-degree unvisited vertices; every degree tie is resolved
by vertex ID.

## Contract

Input is `[n,m,(u,v)*m]` for an undirected simple graph with `1<=n<=8` and
`0<=m<=n(n-1)/2`. Loops, repeated undirected edges, out-of-range endpoints,
and malformed frames return `-1`. Starting with the component whose
minimum-degree root has the smallest `(degree,ID)` pair, run BFS. Enqueue each
vertex's unvisited neighbors in ascending `(degree,ID)` order and mark them
when enqueued. Concatenate component BFS sequences in discovery order, then
reverse the complete sequence.

The scalar result is `(bandwidth << 24) | rank_word`. The bandwidth is the
largest absolute rank difference over an edge, or zero when there are no
edges. The rank word stores the vertex at rank `i` in three bits beginning at
bit `3*i`, with the earliest rank in the least-significant chunk. Invalid
input returns `-1`.

The ports use bounded adjacency tables and insertion sorting of each
discovered neighbor set, taking `O(n^3)` worst-case time and `O(n^2)` auxiliary
space for `n<=8`. The independent reference uses a boolean adjacency matrix
and queue traversal rather than the primary's adjacency bitsets.

This is distinct from local
[`bandwidth_allocation`](../../b/bandwidth_allocation/README.md), which assigns
resource bandwidth and does not order a graph or reduce matrix bandwidth.
Reverse Cuthill–McKee is a heuristic ordering; the benchmark reports its
result and does not assert that the permutation minimizes bandwidth.

## References and rights

E. Cuthill and J. McKee, “Reducing the bandwidth of sparse symmetric
matrices,” ACM National Conference (1969),
[DOI 10.1145/800195.805928](https://doi.org/10.1145/800195.805928).
W.-H. Liu and A. H. Sherman, “Comparative Analysis of the Cuthill–McKee and
the Reverse Cuthill–McKee Ordering Algorithms for Sparse Matrices,” *SIAM
Journal on Numerical Analysis* 13(2) (1976),
[DOI 10.1137/0713020](https://doi.org/10.1137/0713020). Algorithm
descriptions only; no source code or paper text is copied.

See [`workload.json`](workload.json) for deterministic fixtures and the
precise packing convention.
