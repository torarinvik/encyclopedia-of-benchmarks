# Count exact-length directed walks

This draft counts directed walks from one vertex to another with exactly `k`
edges modulo 1,000,000,007. Vertices and edges may repeat; each adjacency
entry gives the multiplicity of parallel edges. Binary matrix powering and
selected powers applied to a source vector handle large edge counts.

Input is `[n,k,source,target,multiplicities...]`, with `1 <= n <= 16`,
`0 <= k <= 1000000000`, zero-based source and target, and `n*n` row-major
multiplicities in `0..100`. The frame has at most 260 words, with 261 as the
parseable malformed-frame limit. A zero-edge walk counts as one if source and
target coincide and zero otherwise. Return the count modulo 1,000,000,007, or
`-1` for a malformed or null frame.

Matrix powering costs `O(n² + n³ log(k+1))` time including validation and
`O(n²)` space. Products and each reduced accumulator fit signed 64-bit
arithmetic. The separate [`fixed_length_walk_minplus`](../fixed_length_walk_minplus/README.md)
uses the min-plus semiring for weighted shortest walks; the existing
[`matrix_exponentiation`](../../m/matrix_exponentiation/README.md) operates on
companion matrices for a recurrence rather than arbitrary adjacency matrices.

The [CP-Algorithms article](https://cp-algorithms.com/graph/fixed_length_paths.html)
is used solely for the mathematical idea; no source prose, code or examples
are copied. Two independently organized reference drafts and drafts in all ten
languages are uncompiled and unrun. Elisa uses a bounded view after its ABI
guard. A workload, source inventory checker, rights note, and scalar runner and
verifier integration are drafted; none has been executed. The verifier source
specifies short-walk reference comparisons and complete-graph closed forms.
