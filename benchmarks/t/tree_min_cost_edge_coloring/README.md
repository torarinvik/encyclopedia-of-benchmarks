# Minimum-cost proper edge coloring of a tree — in progress

Each edge receives one of `k` labeled colors; edges incident to the same vertex
must have different colors. Every color has one shared nonnegative cost, and
the objective is to minimize the total cost over edges. This is different from
[`tree_min_cost_proper_coloring`](../tree_min_cost_proper_coloring/README.md),
which assigns costs to vertex colors and allows siblings to share a color.

The reserved scalar contract is `[n,k,parent[1..n-1],cost[0..k-1]]` with
`1 <= n <= 64`, `1 <= k <= 16`, `0 <= parent[v] < v`, and color costs in
`0..1000000`. Length must equal `n+1+k`, at most 81; 82 is the parseable
malformed-frame limit. Return the minimum total cost, `-2` when a vertex has
degree greater than `k`, or `-1` for malformed or null input. Validation
precedes infeasibility. A one-vertex tree costs zero.

The planned measured algorithm is the bottom-up cost-edge-coloring method of
[Zhou and Nishizeki](https://doi.org/10.1023/B:JOCO.0000021940.40066.0c):
sort colors by cost, retain only degree-sensitive states for each vertex, and
use an all-deletions minimum-cost matching computation to obtain the missing
color alternatives. The paper's optimized algorithm has `O(n Δ²)` time and
`O(n)` DP-table space for maximum degree `Δ`. These drafts additionally read
and sort `k` supplied color costs, adding `O(k log k)` with comparison sort
or `O(k²)` with insertion sort. A port must implement and
justify the matching-sensitivity step before claiming those bounds. The
alternative global reduction of [Ito et al.](https://doi.org/10.1587/transinf.E94.D.190)
is a separate method and is not the planned kernel.

The independently written [fast construction draft](fast_reference.py) uses
one rectangular minimum-cost matching per vertex and shortest alternating
exchanges to compute all single-column deletion costs. A saturated root uses
a square assignment because no parent color is reserved. This proposed
sensitivity construction has not been checked against the independent oracles
or compiled ports; its DP's `O(n Δ²)` time relies on its `O(d³)` assignment
and exchange passes and on the sorted-color state reduction. The
[reference drafts](reference.py) use subset
assignment and exhaustive edge-color enumeration only for small color and tree
bounds. They deliberately do not implement the target fast algorithm or prove
its full-range behavior. A [cross-reference draft](verification_cases.py)
specifies exhaustive small assignment deletion and tree cases, including
equal-cost ties, plus full-range chain and star cases; it has not been executed.
The paper is used for mathematical ideas only; no
source code, prose or examples are copied. The [C draft](../../../c/t/tree_min_cost_edge_coloring.c),
[C++ draft](../../../cpp/t/tree_min_cost_edge_coloring.cpp), [Rust draft](../../../rust/t/tree_min_cost_edge_coloring.rs),
the [Elisa draft](../../../elisa/t/tree_min_cost_edge_coloring.elisa), and the
[Nim draft](../../../nim/t/tree_min_cost_edge_coloring.nim), and the
[Zig draft](../../../zig/t/tree_min_cost_edge_coloring.zig), and the
[Odin draft](../../../odin/t/tree_min_cost_edge_coloring.odin), and the
[C3 draft](../../../c3/t/tree_min_cost_edge_coloring.c3) use bounded
arrays for the matching and sensitivity computation. They have not
been compiled or run. An independently authored workload covers saturated
stars, paths, branching, equal and unsorted prices, infeasibility and validation precedence.
A draft source inventory checker checks fixtures against independent small
oracles and expects all ten ports. Elisa uses
bounded views after its ABI boundary. Two other ports, suite registration, and
runtime validation remain outstanding.
