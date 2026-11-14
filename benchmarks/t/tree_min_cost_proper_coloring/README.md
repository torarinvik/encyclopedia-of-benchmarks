# Minimum-cost proper coloring of a rooted tree

Each tree vertex must receive one of `k` colors, with adjacent vertices using
different colors. The objective is the minimum sum of the supplied
vertex-specific color costs. Children of the same parent may share a color.
The timed draft evaluates subtree dynamic-programming tables from leaves to
root. For each child, its two smallest color costs allow every parent color to
be updated in linear time in `k`.

Input is `[n,k,parent[1..n-1],costs...]`, where `1 <= n <= 64`, `1 <= k <= 16`,
each `parent[v]` is in `0..v-1`, and `n*k` row-major costs are in
`0..1000000`. The parent encoding ensures a single rooted tree. Exact input
length is `n+1+n*k`, at most 1089; 1090 is the parseable malformed-frame limit.
Return the minimum cost in `0..64000000`, `-2` if `k=1` and `n>1`, and `-1`
for malformed or null input. Input validation precedes the infeasibility check.

The optimized DP takes `O(n*k)` time and `O(n*k)` auxiliary space; the
separate direct reference checks each possible child color per parent color
and takes `O(n*k²)` time. The [CP-Algorithms Hungarian article](https://cp-algorithms.com/graph/hungarian-algorithm.html)
provides the coloring idea only. Its proposed assignment of distinct colors
to siblings is a stronger constraint than ordinary adjacency coloring and is
not used here. No source prose, code or examples were copied. The local
[`graph_coloring`](../../g/graph_coloring/README.md) instead counts colorings
of small general graphs and has no per-vertex costs.

Two independent reference drafts and drafts in all ten languages are uncompiled
and unrun. Elisa uses a bounded view after its ABI guard. An independently
authored workload, rights note, package inventory checker, and scalar runner and
verifier integration are drafted. The verifier source specifies maximum-size
chains and stars with closed-form results, as well as validation precedence;
none has been executed.
