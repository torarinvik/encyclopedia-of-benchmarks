# Range-constraint topological feasibility

Determine whether vertices `0..n-1` can be ordered to satisfy a set of range
precedence constraints. This extends the explicit-edge [`topological_sort`](../../t/topological_sort/README.md)
profile: some constraints require every vertex in a range to precede or follow
a target, while others require at least one range vertex to precede it.

The proposed `i64_array_scalar` frame is `[n, m, (kind, l, r, target)...]`.
Here `1 <= n <= 4096`, `0 <= m <= 8192`, ranges are nonempty half-open
intervals `0 <= l < r <= n`, and `target` is outside `[l,r)`. Kind 1 requires
the target before every range vertex; kind 2 requires every range vertex before
the target; kind 3 requires at least one range vertex before the target. Return
1 for a feasible ordering, 0 for an infeasible one, and -1 for malformed input.
The kernel constructs an ordering internally but reports only feasibility.

The draft uses three segment-tree-shaped event networks: downward all-of
propagation, upward all-of propagation, and upward first-arrival propagation.
Each interval decomposes into O(log n) canonical nodes. A first-arrival node
fires once, after any predecessor fires; ordinary nodes fire only after all
predecessors fire. A queue processes ready nodes, and feasibility holds exactly
when all original vertices fire. The graph has O(n + m log n) vertices and
edges and takes O(n + m log n) time and space. The independent reference
expands ranges directly and repeatedly selects an eligible vertex; it is not
the benchmark kernel.

The [Library Checker proposal](https://github.com/yosupo06/library-checker-problems/issues/1428)
is used as an idea index. The contract, event graph, reference, and code are
independently authored; no issue text, implementation, or fixtures are copied.

Reserved and in progress: ten language event-graph drafts and a direct reference
are present, with initial fixtures, workload validation and scalar-suite
registration.
Fixtures include first-arrival constraints spanning multiple tree nodes, with
both a free predecessor and a cycle. The verifier specifies all pairs of
valid three-vertex constraints, compares the greedy reference to independent
permutation enumeration, and includes maximum vertex/constraint frames.
Nothing has been compiled or executed.
