# Hypergraph incidence-graph encoding

This package benchmarks the representation reduction from an indexed
hyperedge family to its two-color bipartite incidence graph. It is a
graph-construction benchmark; it does not perform nauty labeling, graph
isomorphism testing, or hypergraph isomorphism testing.

## Contract

- ABI: `i64_array_bytes_output`; symbol:
  `hypergraph_incidence_graph_encoding`.
- Input is `[n,m,(size,vertex_ids...)*m]`. The hypergraph has `1<=n<=8`
  vertices and `0<=m<=12` indexed hyperedges; each hyperedge has zero to `n`
  distinct vertex IDs in `0..n-1`. Equal hyperedges and empty hyperedges are
  allowed and remain distinct by their input index.
- The output is `[N,K,c_0,...,c_(N-1),u_0,v_0,...,u_(K-1),v_(K-1)]`.
  Original vertices retain IDs `0..n-1`; hyperedge-nodes have IDs
  `n..n+m-1` in input order. `N=n+m`; `K` is the number of incidences.
  Colors are `0` for original vertices and `1` for hyperedge-nodes. Incidences
  are emitted in lexicographic `(vertex_id, hyperedge_node_id)` order.
- The output is a canonical encoding for this input labeling. It preserves the
  hypergraph's vertex-versus-hyperedge classes; it does not canonicalize the
  original hypergraph under relabeling.
- Invalid input, including a repeated vertex within one hyperedge, returns
  `-1`; null or short output returns `-2` without modifying output. Maximum
  valid/parseable input lengths are 110/111 i64 words; maximum output size is
  1712 bytes.
- The matrix-based language ports take `O(nm + S + K)` time and `O(nm)` space,
  where `S` is the number of listed incidences. The list-scanning primary
  reference takes `O(n^2m + K)` time.

The primary reference stores each hyperedge's listed vertex IDs and probes
membership while serializing. The independent reference first builds an
incidence matrix, then serializes its true entries. Fixtures cover empty and
repeated hyperedges, singleton and shared incidences, complete incidence,
repeated vertices within an edge, framing, and output capacity.

## Source and rights

The *Encyclopedia of Algorithms* chapter [“Graph Isomorphism”](https://doi.org/10.1007/978-1-4939-2864-4_172)
describes the hypergraph-incidence reduction and its equivalence for
color-preserving isomorphism. The construction here is a clean-room bounded
profile of that representation transform. No source code, prose, examples,
figures, or test data are copied. See [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/h/hypergraph_incidence_graph_encoding.c`](../../../c/h/hypergraph_incidence_graph_encoding.c) |
| C3 | [`c3/h/hypergraph_incidence_graph_encoding.c3`](../../../c3/h/hypergraph_incidence_graph_encoding.c3) |
| C++ | [`cpp/h/hypergraph_incidence_graph_encoding.cpp`](../../../cpp/h/hypergraph_incidence_graph_encoding.cpp) |
| Elisa | [`elisa/h/hypergraph_incidence_graph_encoding.elisa`](../../../elisa/h/hypergraph_incidence_graph_encoding.elisa) |
| Mojo | [`mojo/h/hypergraph_incidence_graph_encoding.mojo`](../../../mojo/h/hypergraph_incidence_graph_encoding.mojo) |
| Nim | [`nim/h/hypergraph_incidence_graph_encoding.nim`](../../../nim/h/hypergraph_incidence_graph_encoding.nim) |
| Odin | [`odin/h/hypergraph_incidence_graph_encoding.odin`](../../../odin/h/hypergraph_incidence_graph_encoding.odin) |
| Rust | [`rust/h/hypergraph_incidence_graph_encoding.rs`](../../../rust/h/hypergraph_incidence_graph_encoding.rs) |
| V | [`v/h/hypergraph_incidence_graph_encoding.v`](../../../v/h/hypergraph_incidence_graph_encoding.v) |
| Zig | [`zig/h/hypergraph_incidence_graph_encoding.zig`](../../../zig/h/hypergraph_incidence_graph_encoding.zig) |

See [workload.json](workload.json), both oracle references, and the callable
static package inventory [verify_workload.py](verify_workload.py).
