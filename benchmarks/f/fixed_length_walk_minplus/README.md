# Exact-length shortest walk by min-plus powers

This draft finds the least weight of a directed walk containing exactly `k`
edges. Repeated vertices, loops and negative edge weights are allowed. Binary
exponentiation combines distance matrices with min-plus multiplication. This
is distinct from ordinary arithmetic matrix powers and from unrestricted
all-pairs shortest paths. [`apsp_min_plus_repeated_squaring`](../../a/apsp_min_plus_repeated_squaring/README.md)
also squares min-plus matrices, but its zero diagonal represents walks of at
most a given length and it stops after covering simple shortest paths. This
profile uses an arbitrary exact edge count, accepts negative cycles, and
accumulates selected powers into a single-source vector. The separate
[`min_plus_distance_product`](../../m/min_plus_distance_product/README.md)
performs one matrix product rather than exponentiation.

Input is `[n,k,source,target,weights...]`, where `1 <= n <= 16`,
`0 <= k <= 1000000`, vertices are numbered `0..n-1`, and the remaining `n*n`
words form a row-major adjacency matrix. Each entry is an edge weight in
`[-100,100]` or `1000000` to indicate no edge. Only one edge per ordered pair
is represented. The exact frame has at most 260 words; 261 is the largest
parseable malformed frame. The zero-edge walk has weight zero exactly when
source equals target. Return the minimum weight, `-100000001` when no such
walk exists, or `-100000002` for malformed or null input. The sentinel values
are outside the range of all valid path weights.

The matrix-power implementation uses `O(n² + n³ log(k+1))` time, including
input validation, and `O(n²)` space. The independently authored small-case reference advances a distance
vector once per edge, which is suitable for checking short lengths but not
the full exponent range. The [CP-Algorithms discussion](https://cp-algorithms.com/graph/fixed_length_paths.html)
supplies the mathematical idea only; no source text, examples or code are
copied. Drafts in all ten languages and the references are uncompiled and
unrun. Elisa uses a bounded input view after its ABI guard. An independently
authored workload covers zero-length walks, negative cycles, unreachable parity,
maximum length, a four-vertex cycle at the maximum length, and malformed input.
A source inventory checker and draft scalar runner and verifier integration
includes independent short-walk comparisons, closed-form full-size dense
graphs, and boundary cases; it is unexecuted.
