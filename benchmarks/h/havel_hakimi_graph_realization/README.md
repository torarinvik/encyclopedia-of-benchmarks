# Havel–Hakimi graph realization

Construct one deterministic simple undirected graph from a supplied degree
sequence. The local `erdos_gallai_graphical_sequence` profile returns only a
graphical/non-graphical decision using the Erdős–Gallai inequalities. This
package returns an explicit edge list using the constructive Havel–Hakimi
reduction. Its Havel–Hakimi decision oracle is not a graph constructor.

## Contract

The `i64_array_bytes_output` input is `[N,degree_0,...,degree_(N-1)]`, with
`0<=N<=8` and each degree in `0..N-1`. Vertices retain their input indices.
Repeatedly select the vertex with the largest positive residual degree, using
the smallest vertex ID on a tie. Connect it to the next `d` remaining vertices
ordered by residual degree descending and then vertex ID ascending. Emit each
edge when created and normalize its endpoints as `u<v`. Invalid framing or a
degree outside the simple-graph range returns `-1` before checking the output
buffer.

For a graphical sequence the little-endian signed-i64 output is
`[1,edge_count,u0,v0,...]`. A valid non-graphical sequence produces `[0]`.
The maximum valid and parseable input lengths are 9 and 10 words. At most 28
edges are emitted, for a maximum output size of 464 bytes. A null output buffer
or insufficient capacity returns `-2` without writing.

The primary oracle repeatedly sorts a bounded candidate list. The independent
oracle first checks the Erdős–Gallai inequalities and then uses a priority
queue with the same explicit tie key to produce the canonical edge list. It
also provides a certificate check that verifies simplicity and exact degree
counts independently of construction.

## Sources and provenance

NetworkX's official [`havel_hakimi_graph` documentation](https://networkx.org/documentation/stable/reference/generated/networkx.generators.degree_seq.havel_hakimi_graph.html)
describes this construction as repeatedly attaching the highest-degree vertex
to the other highest-degree vertices and reducing those residual degrees. The
method is attributed to Hakimi, [“On Realizability of a Set of Integers as
Degrees of the Vertices of a Linear Graph. I,” SIAM Journal on Applied
Mathematics 10(3), 1962](https://doi.org/10.1137/0110037). The independent
graphicality check follows the Erdős–Gallai characterization, summarized in
NetworkX's [`is_valid_degree_sequence_erdos_gallai` documentation](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.graphical.is_valid_degree_sequence_erdos_gallai.html).
Only algorithm descriptions are used; no implementation, task text, examples,
or code are copied. See [RIGHTS.md](RIGHTS.md).

## Workload and inventory

[`workload.json`](workload.json) covers empty and complete graphs, isolates,
star and path degree sequences, tie behavior, a non-graphical sequence,
malformed frames, and output-buffer errors. The primary and independent
references are listed in [`INVENTORY.md`](INVENTORY.md). The static package
review helper is [`check_inventory.py`](check_inventory.py); it has not been
run.

## Language ports

| Language | Source |
|---|---|
| C | [`c/h/havel_hakimi_graph_realization.c`](../../../c/h/havel_hakimi_graph_realization.c) |
| C3 | [`c3/h/havel_hakimi_graph_realization.c3`](../../../c3/h/havel_hakimi_graph_realization.c3) |
| C++ | [`cpp/h/havel_hakimi_graph_realization.cpp`](../../../cpp/h/havel_hakimi_graph_realization.cpp) |
| Elisa | [`elisa/h/havel_hakimi_graph_realization.elisa`](../../../elisa/h/havel_hakimi_graph_realization.elisa) |
| Mojo | [`mojo/h/havel_hakimi_graph_realization.mojo`](../../../mojo/h/havel_hakimi_graph_realization.mojo) |
| Nim | [`nim/h/havel_hakimi_graph_realization.nim`](../../../nim/h/havel_hakimi_graph_realization.nim) |
| Odin | [`odin/h/havel_hakimi_graph_realization.odin`](../../../odin/h/havel_hakimi_graph_realization.odin) |
| Rust | [`rust/h/havel_hakimi_graph_realization.rs`](../../../rust/h/havel_hakimi_graph_realization.rs) |
| V | [`v/h/havel_hakimi_graph_realization.v`](../../../v/h/havel_hakimi_graph_realization.v) |
| Zig | [`zig/h/havel_hakimi_graph_realization.zig`](../../../zig/h/havel_hakimi_graph_realization.zig) |
