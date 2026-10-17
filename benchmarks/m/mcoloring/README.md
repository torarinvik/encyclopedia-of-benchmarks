# M-coloring feasibility on forests

This benchmark preserves the boolean result of the pinned Java BFS coloring
method on bounded simple undirected forests. It does not claim to solve general
exact m-colorability.

## Input and output

The signed 64-bit input array is `[n, m, mask_0, ..., mask_(n-1)]`. There are
`n` vertices numbered from zero in this contract; bit `j` in `mask_i` means
there is an edge between vertices `i` and `j`. The adapter maps vertex `i` to
the pinned Java method's node index `i+1`. The input must contain exactly `n`
masks, with `0 <= n <= 14` and `1 <= m <= 14`.

Adjacency masks must have no bits outside the first `n` positions, no self
bits, and must be symmetric. The represented graph must be acyclic; a graph
with several tree components or isolated vertices is allowed. Invalid framing,
masks, color limits, or cyclic graphs return `-1`.

For a valid input the scalar output is `1` when the source returns `true`, and
`0` when it returns `false`. Every source node starts with color 1. The method
visits start vertices in increasing order with BFS, and when an edge connects
equal current colors it increments the neighbor's color by one. On a forest
this assigns only colors 1 and 2: isolated-only graphs return true for any
valid `m`, a forest containing an edge returns false for `m=1`, and it returns
true for `m>=2`. These outcomes describe this source routine on the restricted
input family; they are not a general coloring solver's feasibility rule.

## Pinned source

The source is TheAlgorithms/Java [`MColoring.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/backtracking/MColoring.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`, method `isColoringPossible`.

The bounded workload and independent oracle are [`workload.json`](workload.json)
and [`benchmarks/mcoloring_oracle.py`](../../mcoloring_oracle.py).
