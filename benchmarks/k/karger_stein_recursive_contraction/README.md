# Recursive Karger–Stein contraction

Run one bounded two-branch recursive contraction profile on a connected
undirected multigraph. This is a reproducible realization of a randomized
algorithm: the supplied rank tape selects edges; it does not assert a random
distribution, and the returned cut is not guaranteed globally minimal.

The `i64_array_scalar` frame is `[n,m,q,(u,v)*m,ranks*q]`. Require
`2<=n<=12`, `1<=m<=32`, `0<=q<=64`, vertices in `0..n-1`, no input
self-loops, and a connected graph. Parallel edges are allowed and count
individually. Require exactly `3+2*m+q` words, at most 131; an extra word is
parseable and invalid. Return `-1` for null or malformed input, an invalid
rank, or a tape that is not consumed exactly. Otherwise return the number of
original edges crossing the best cut produced by the recursive profile.

For a graph with at most six supervertices, enumerate its nontrivial cuts and
return the exact minimum. For s>6, independently contract two copies down to
`ceil(s/sqrt(2))+1` supervertices, then recurse on each and take the smaller
cut. The exact targets for s=7..12 are `6,7,8,9,9,10`. For each contraction,
scan original edge records in input order and retain those joining different
current components. The next tape word is the zero-based index into that
list. Consume the full first branch (contraction and recursion) before the
second branch. Vertices in a copy remain represented by sets of original
vertices; edge multiplicity is preserved. Connectedness guarantees a
cross-component edge while more than one component remains.

At this bound, the longest tape is 64 ranks, attained at n=12. In general,
two branches reduce s by a factor near sqrt(2); this profile additionally
scans all m original edges at each contraction and uses exhaustive cut
enumeration only at the fixed six-component base. A direct label-and-cut
enumeration reference is drafted independently of the planned disjoint-set
implementations.

The straightforward ports use uncompressed parent chains. A contraction scans
up to m edges with O(n) root lookup, and the recursion has O(n²) bounded-size
leaves; a conservative scaling bound for this representation is
O(m*n²*log n) time and O(m+q+n*log n) auxiliary space, excluding the input.
The fixed n<=12 profile does not implement asymptotically faster edge sampling.

The [MIT randomized min-cut notes](https://courses.csail.mit.edu/6.856/21/Notes/n19-mincut.html)
describe recursive contraction. Only the mathematical idea is used; the
contract, reference, and ports are independently authored. This differs from
the repository's single [`karger_contraction_trial`](../karger_contraction_trial/README.md)
and exact [`stoer_wagner`](../../s/stoer_wagner/README.md) workloads.

Status: contract, independent reference, ten language drafts, workload,
package checker, and scalar-suite integration are drafted. The verifier source
also specifies exhaustive small graphs and a maximum frame. No program or check
has been run; all drafts remain unverified.
Two seven-vertex fixtures distinguish a second branch that preserves a bridge
from two branches that both contract it, yielding cuts of one and two.
