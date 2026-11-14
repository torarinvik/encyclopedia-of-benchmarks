# Penalty-search invariants

Each two-state scan compares `(penalized_score, selected_count)`
lexicographically, preferring more selections on a tie. Increasing the penalty
cannot increase that chosen count. The binary search finds the largest integer
penalty with count at least `k` and adds back `k` penalties.

For the concavity required by this recovery, map position `i` to edge `i` of a
path on `n+1` vertices. Non-adjacent positions become a matching. A path is
bipartite, and the minimum cost of an exact-cardinality bipartite matching is
discretely convex in its cardinality; negating edge weights gives the required
concave maximum-weight sequence. This explains why a penalty breakpoint may
skip counts while still yielding the exact value when the penalty is restored.
For example, weights `[10,0,10]` have a penalty at which both zero and two
selections are optimal; restoring one penalty still gives the one-selection
optimum. The workload includes this tie case.

Any feasible weight sum has absolute value at most 64000, so the difference
between two feasible sums is at most 128000. Penalties `-256001` and `256001`
therefore force maximum and zero cardinality respectively, even with negative
weights. The result and all penalized intermediate scores fit signed 64-bit
integers. On the odd 31-position alternating workload, selecting 16 positions
forces every even position and gives -16000; selecting 15 positive odd
positions gives 15000. This deliberately exercises a large negative
breakpoint. These are static arguments, not evidence that a port has compiled
or passed the reference checks.
