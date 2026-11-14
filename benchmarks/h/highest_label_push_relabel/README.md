# Highest-label push–relabel maximum flow

This draft initializes a preflow from the source and repeatedly chooses an
active nonterminal of greatest height, breaking height ties by vertex ID.
It pushes along an admissible residual arc in ascending destination order;
if none exists, it relabels the vertex to one above its least-height residual
neighbor. The next active vertex is chosen again after each push or relabel.
The existing [`push_relabel`](../push_relabel/README.md) benchmark chooses the
first active vertex by scan order, so the scheduling policy differs.

The scalar input is `[N,M,source,sink,(u,v,capacity)*M]`, with `2<=N<=16`,
`0<=M<=64`, vertices numbered `1..N`, distinct terminals, no self-loops,
capacities `0..100`, and parallel or antiparallel edges allowed. Exact length
is `4+3*M`, at most 196 words; 197 is the parseable malformed-frame limit.
Return the maximum flow, at most 6400, or `-1` for invalid or null input.
Parallel capacities are combined in a residual matrix.

This bounded implementation scans all vertices to select the active vertex
and scans possible destinations for each push or relabel. Using the generic
`O(N²E)` push bound and `O(N)` scans per operation gives a conservative
`O(N³E + N³)` time bound and `O(N²)` space, where `E` counts distinct
directed residual pairs. It does not claim the sharper complexity of optimized
highest-label implementations. The [CP-Algorithms improved push–relabel article](https://cp-algorithms.com/graph/push-relabel-faster.html)
is used for the algorithmic idea only; its text is CC BY-SA 4.0. The contract,
code, and eventual fixtures are independently authored. The primary draft
models highest-label preflow; the independent reference enumerates cuts. Drafts
in all ten languages, a workload, rights note, package checker, and scalar
runner/verifier registration are present. The verifier source specifies small
capacity combinations, transposed networks, maximum frames, and null input;
it compares the primary reference with minimum cuts and scaled Dinic. The
workload includes a source with a nonminimal vertex ID and a constrained sink
with excess circulating through antiparallel arcs. The Elisa draft uses a
bounded input view and fixed arrays. Nothing has been compiled or run.
