# Capacity-scaled Dinic maximum flow

This draft computes maximum flow with BFS level graphs and blocking flows, but
only follows residual arcs whose capacity is at least the current power-of-two
threshold. It starts at the largest power of two no greater than the largest
aggregated directed capacity and halves the threshold until one. A zero-capacity
network returns zero. Parallel directed capacities are aggregated; antiparallel
capacities share the usual residual matrix. The final threshold of one finds a
maximum integral flow. The threshold phases distinguish this method from the
ordinary positive-residual [`dinic_maxflow`](../dinic_maxflow/README.md) ports.

The scalar input is `[N,M,source,sink,(u,v,capacity)*M]`. Vertices use IDs
`1..N`, with `2<=N<=16`, `0<=M<=64`, distinct source and sink, no self-loops,
capacities in `0..100`, and parallel or antiparallel edges permitted. The
exact input length is `4+3*M`, at most 196 words; 197 is the largest parseable
malformed frame. Return the maximum flow, at most 6400, or `-1` for malformed
or null input. Aggregation can produce a residual capacity greater than an
individual input edge capacity.

For this dense-matrix version, each threshold phase has at most `N-1` level
graphs, with `O(N^3)` time per blocking-flow computation as a conservative
bound. With `C` the largest aggregated capacity, total time is
`O(N^4 log(max(C,2)))` and space is `O(N²)`. This deliberately states a bound
for the bounded dense implementation, not the sharper bounds of specialized
adjacency-list algorithms.

The [MIT blocking-flow notes](https://courses.csail.mit.edu/6.854/21/Scribe/s7-blockingFlows/scribe7.html)
describe capacity scaling; the pinned source of the existing Dinic package
also identifies such a variant. These references provide algorithm ideas only.
The contract, source, and eventual workload are independently authored. The
primary reference uses thresholded level graphs; the independent reference
enumerates all source/sink cuts. Drafts in all ten languages, the workload,
rights note, package checker, and scalar runner/verifier registration are
present. The verifier source specifies small capacity combinations, threshold
transitions, transposed networks, split parallel edges, maximum frames, and null inputs. The Elisa
draft uses bounded views internally. Nothing has been compiled or run.

The workload includes a unit-capacity network where ascending-vertex traversal
first uses edge 2→4 and must subsequently traverse its reverse residual edge
to route both units of flow.
