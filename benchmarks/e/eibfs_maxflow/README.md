# EIBFS maximum flow

Compute a bounded directed-network maximum-flow value with Excesses Incremental
Breadth-First Search (EIBFS). The algorithm maintains a capacity-feasible
pseudoflow and two vertex-disjoint admissible forests. It alternates one-level
forward and reverse growth phases. A connecting residual arc triggers the
paper's root/bottleneck-dependent push rule; any resulting excess in the sink
forest and deficit in the source forest are drained along their tree paths,
with round-robin orphan adoption and relabeling.

## Contract

`i64_array_scalar` input is:

```text
[N, M, source, sink, (from, to, capacity)*M]
```

`N` is 2 through 8; `M` is 0 through 24; vertex IDs are zero-based; source and
sink differ; capacities are 0 through 100; self-loops are invalid. Parallel
and antiparallel arcs are accepted. A null input pointer returns -1 for both
declared lengths 0 and 77. The packed length is exactly `4 + 3*M`, so
the maximum valid and parseable frame lengths are 76 and 77 words. The maximum
possible result is 2,400. Malformed frames return -1.

The reference maintains residual capacities, signed vertex excesses, parent
forests, and monotonically increasing source/sink distance labels. Deterministic
ascending vertex and neighbor scans break ties. Since the maintained state is
a pseudoflow, output extraction uses EIBFS's blocking-cut side: seed the cut
with every source-forest vertex, then close that side under residual reachability
and sum original capacities crossing it. Every source-tree vertex is residual-
reachable from its root; all positive-excess roots are in the source forest,
while deficit roots (including the sink) are in the disjoint sink forest. At
termination, EIBFS's growth separation invariant makes the residual closure a
minimum-cut certificate. This applies the paper's correctness invariant to the
cut extraction; it does not infer a conserved flow value from the pseudoflow's
sink balance. The
independent reference enumerates all source-containing, sink-excluding vertex
subsets and minimizes their directed cut capacity. Both methods use fixed-size
state; ports reserve 8 KiB for residual, balance, forest, queue, and parse state.

The source for this extraction is §2, Lemma 1: during forward growth, a
residual arc from the source forest to a vertex outside it makes its source-side
tail active; the phase terminates only after the frontier is exhausted and no
next level exists. The reverse statement applies to the sink forest. The paper
states that EIBFS correctness relies on this lemma and gives the full proof in
its extended version.

The algorithm description follows Goldberg, Hed, Kaplan, Kohli, Tarjan, and
Werneck, [“Faster and More Dynamic Maximum Flow by Incremental Breadth-First
Search,” ESA 2015](https://www.microsoft.com/en-us/research/publication/faster-and-more-dynamic-maximum-flow-incremental-breadth-first-search/).
This is a clean-room implementation of the paper's method, not a port of its
source code. The workload includes basic, parallel, antiparallel, rerouting,
zero-flow, maximum-flow, maximum-frame, and malformed cases.

See [`workload.json`](workload.json), [`RIGHTS.md`](RIGHTS.md), and the static
inventory checker at [`benchmarks/check_eibfs_maxflow_package.py`](../../check_eibfs_maxflow_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/e/eibfs_maxflow.c`](../../../c/e/eibfs_maxflow.c) |
| C3 | [`c3/e/eibfs_maxflow.c3`](../../../c3/e/eibfs_maxflow.c3) |
| C++ | [`cpp/e/eibfs_maxflow.cpp`](../../../cpp/e/eibfs_maxflow.cpp) |
| Elisa | [`elisa/e/eibfs_maxflow.elisa`](../../../elisa/e/eibfs_maxflow.elisa) |
| Mojo | [`mojo/e/eibfs_maxflow.mojo`](../../../mojo/e/eibfs_maxflow.mojo) |
| Nim | [`nim/e/eibfs_maxflow.nim`](../../../nim/e/eibfs_maxflow.nim) |
| Odin | [`odin/e/eibfs_maxflow.odin`](../../../odin/e/eibfs_maxflow.odin) |
| Rust | [`rust/e/eibfs_maxflow.rs`](../../../rust/e/eibfs_maxflow.rs) |
| V | [`v/e/eibfs_maxflow.v`](../../../v/e/eibfs_maxflow.v) |
| Zig | [`zig/e/eibfs_maxflow.zig`](../../../zig/e/eibfs_maxflow.zig) |
