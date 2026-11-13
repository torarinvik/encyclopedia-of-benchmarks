# ISAP maximum flow

Compute an integral maximum flow on a bounded directed graph using the improved shortest augmenting path (ISAP) method. The initial labels come from a reverse BFS rooted at the sink. DFS augments only along residual arcs whose labels descend by one; when a vertex exhausts its admissible arcs, its label is raised to one plus the smallest residual-neighbor label. Current-arc cursors avoid rescanning already exhausted choices, and the gap rule terminates after a label below the vertex count disappears.

## Contract

`i64_array_scalar` input is:

```text
[N, M, source, sink, (from, to, capacity)*M]
```

There are 2 through 8 vertices, 0 through 24 directed edges, zero-based vertex IDs, distinct source/sink, and capacities in 0 through 100. Self-loops are invalid; parallel and antiparallel arcs are allowed. The packed length is exactly `4 + 3*M`, with maximum valid/parseable lengths 76/77 words. The maximum possible flow is 2400. A valid graph returns its maximum flow; malformed input returns -1. The ports use fixed arrays; declared workspace is 4096 bytes.

The primary oracle uses reverse-BFS distance labels with dynamic relabeling, current arcs, and gap termination. The independent verifier enumerates source-side vertex cuts and minimizes the total capacity crossing the cut. The workload includes residual rerouting, an explicit gap-label termination case, parallel and antiparallel arcs, disconnected terminals, an empty edge set, a maximum-flow graph, maximum-size frames, and malformed records. See [`workload.json`](workload.json).

For at most V active labels and E residual arcs, the bounded ISAP profile has O(V²E) worst-case time and O(V²+E) storage. The capacity matrix combines parallel arcs and handles antiparallel capacities as aggregate residual capacity; this preserves maximum-flow values for the stated integral-capacity contract.

## Provenance and rights

The high-level method description follows the ISAP section of [OI Wiki — Maximum Flow](https://oi-wiki.org/graph/flow/max-flow/#isap). OI Wiki content is published under CC BY-SA 4.0 and SATA; this package uses the algorithm description only. The implementations, fixtures, and oracles are clean-room work: no upstream source, code sample, or prose was copied. See [`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/i/isap_maxflow.c`](../../../c/i/isap_maxflow.c) |
| C3 | [`c3/i/isap_maxflow.c3`](../../../c3/i/isap_maxflow.c3) |
| C++ | [`cpp/i/isap_maxflow.cpp`](../../../cpp/i/isap_maxflow.cpp) |
| Elisa | [`elisa/i/isap_maxflow.elisa`](../../../elisa/i/isap_maxflow.elisa) |
| Mojo | [`mojo/i/isap_maxflow.mojo`](../../../mojo/i/isap_maxflow.mojo) |
| Nim | [`nim/i/isap_maxflow.nim`](../../../nim/i/isap_maxflow.nim) |
| Odin | [`odin/i/isap_maxflow.odin`](../../../odin/i/isap_maxflow.odin) |
| Rust | [`rust/i/isap_maxflow.rs`](../../../rust/i/isap_maxflow.rs) |
| V | [`v/i/isap_maxflow.v`](../../../v/i/isap_maxflow.v) |
| Zig | [`zig/i/isap_maxflow.zig`](../../../zig/i/isap_maxflow.zig) |

The package inventory checker is [`benchmarks/check_isap_maxflow_package.py`](../../check_isap_maxflow_package.py).
