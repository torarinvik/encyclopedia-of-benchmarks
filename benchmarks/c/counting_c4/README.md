# Per-edge C4 Counting

For every edge ID in an undirected multigraph, count the edge-ID triples that
form a four-cycle with it. This follows the [Library Checker task
definition](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/counting_c4/task.md)
and its [official limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/counting_c4/info.toml).
The ports and oracle here are clean-room implementations.

## Contract

The `i64_array_bytes_output` input is `[n, m, (u, v)*m]`. Vertices are
zero-based, with `2 <= n <= 8` and `1 <= m <= 12` locally; the official task
allows up to 300,000 vertices and edges. Self-loops are invalid. Parallel edges
are valid and are distinguished by input index. For each edge `i`, output the
number of unordered triples of other edge IDs whose four selected edges form a
subgraph isomorphic to `C4`; extra graph edges do not invalidate a cycle. The
`m` signed 64-bit answers are serialized as `m` unsigned 64-bit little-endian
integers. Invalid input returns `-1`; a null output pointer or insufficient
capacity returns `-2`. Input validation precedes output errors, and failures
write no bytes.

## Algorithm and bounds

Build an undirected edge-multiplicity matrix. For each input edge `(u,v)`, sum
`mult[u][a] * mult[a][b] * mult[b][v]` over ordered internal vertices `a,b`
that are distinct from one another and from `u,v`. Each term counts edge-ID
choices for the length-three path from `u` to `v`; together with the fixed edge
it gives one four-cycle. The runtime is `O(m + m*n^2)` and working space is
`O(n^2 + m)`.

This is a per-edge counting task; local triangle and fixed-size clique counters
return aggregate counts for different subgraphs. The independent oracle
enumerates four-edge-ID subsets and checks whether each selected multigraph is
a connected 2-regular graph on four vertices. Its search is bounded by
`C(12,4)` subsets.

See [`workload.json`](workload.json) and the independent
[edge-subset oracle](../../counting_c4_oracle.py). No implementation has been
run or compiled.

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/counting_c4.c`](../../../c/c/counting_c4.c) |
| C3 | [`c3/c/counting_c4.c3`](../../../c3/c/counting_c4.c3) |
| C++ | [`cpp/c/counting_c4.cpp`](../../../cpp/c/counting_c4.cpp) |
| Elisa | [`elisa/c/counting_c4.elisa`](../../../elisa/c/counting_c4.elisa) |
| Nim | [`nim/c/counting_c4.nim`](../../../nim/c/counting_c4.nim) |
| Odin | [`odin/c/counting_c4.odin`](../../../odin/c/counting_c4.odin) |
| Rust | [`rust/c/counting_c4.rs`](../../../rust/c/counting_c4.rs) |
| V | [`v/c/counting_c4.v`](../../../v/c/counting_c4.v) |
| Zig | [`zig/c/counting_c4.zig`](../../../zig/c/counting_c4.zig) |
| Mojo | [`mojo/c/counting_c4.mojo`](../../../mojo/c/counting_c4.mojo) |
