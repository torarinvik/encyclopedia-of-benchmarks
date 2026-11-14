# Weighted binary search for a path independent set

Select exactly `k` positions from a weighted path, with no two selected
positions adjacent, to maximize their weight sum. The `i64_array_scalar`
frame is `[n,k,weights...]`: `0<=n<=128`, `0<=k<=ceil(n/2)`, and weights are
in `[-1000,1000]`. The frame must have exactly `n+2` words. Return the optimum,
or `-1000000000` for malformed or null input. The empty selection is zero;
valid results lie in `[-64000,64000]`. The longest valid and parseable frames
contain 130 and 131 words respectively.

The target method uses weighted binary search (also called WQS or the aliens
trick): subtract a per-selection penalty, optimize the unconstrained path
independent set by a two-state scan, and break equal scores in favor of more
selections. Binary search for the largest integer penalty whose optimal count
is at least `k`, then restore `k` penalties. The value function is discretely
concave for path independent sets, which makes this recovery valid. Search the
inclusive penalty range `[-256001,256001]`; the endpoints dominate the
largest possible difference between any two feasible weight sums. Target
complexity is O(n log W) time and O(1) auxiliary space, with W=256001. The independent reference keeps the
exact selected count in its dynamic-programming state.
The [implementation notes](IMPLEMENTATION_NOTES.md) describe the concavity
argument, tie rule, penalty bounds, and a workload with a large breakpoint.

The local [`max_non_adjacent_sum`](../../m/max_non_adjacent_sum/README.md)
has no exact-cardinality constraint; the general
[`maximum_independent_set`](../../m/maximum_independent_set/README.md) is an
unweighted graph problem. The [OI Wiki weighted-binary-search discussion](https://oi-wiki.org/dp/opt/wqs-binary-search/)
describes the method. Contract, code and fixtures are independently written;
no external source text or examples are copied.

Reserved for root. Drafts in all ten languages, an independent reference,
the workload, and scalar-suite registration are present but unverified. The
verifier draft cross-checks the reference against small subset enumeration.
Nothing has been compiled or run.
