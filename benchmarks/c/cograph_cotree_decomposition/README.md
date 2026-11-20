# Cograph cotree decomposition

This bounded profile recognizes cographs and serializes their reduced cotree.
Cographs are the graphs generated from one vertex by repeated disjoint-union
and complete-join operations. The cotree records those operations and the
original vertices.

## Contract

- Exported symbol: `cograph_cotree_decomposition`; ABI:
  `i64_array_bytes_output`.
- Input: `[N,M,(u,v)*M]`, with `1<=N<=12` and
  `0<=M<=min(66,N*(N-1)/2)`. The graph is
  undirected, simple, and unweighted; each edge is an unordered pair of
  distinct zero-based vertex IDs. Either endpoint order is accepted, but a
  repeated unordered edge is invalid.
- Exact input length is `2+2*M`; maximum valid and parseable lengths are 134
  and 135 signed 64-bit words. Invalid input returns `-1`.
- A valid non-cograph writes one byte `00` and returns 1. A cograph writes
  byte `01`, followed by preorder records, and returns the byte count.
- Each tree record is two bytes. A leaf is `(00, vertex_id)`. A disjoint-union
  node is `(01, child_count)`. A complete-join node is `(02, child_count)`.
  Children are ordered by their smallest contained vertex ID. Internal labels
  alternate; every internal node has at least two children. The reduced cotree
  is unique under this child ordering.
- Invalid input is checked before output errors. A null output or a capacity
  below the required byte count returns `-2`; errors leave output untouched.
- The maximum output is 47 bytes: at most 12 leaves and 11 internal nodes,
  plus the one-byte cograph status.

## Recursive decomposition profile

For each induced subgraph with more than one vertex, first find its connected
components. More than one component creates a disjoint-union node and each
component is processed recursively. Otherwise find the connected components
of its complement. More than one co-component creates a complete-join node
and each co-component is processed recursively. If both the graph and its
complement are connected, the input is not a cograph and the output is `00`.
A single vertex becomes a leaf. Components are discovered in increasing
minimum-vertex order, which fixes the serialization order.

This bounded recursive component profile follows the cograph construction
and cotree characterization; it does not claim the linear-time implementation
of the cited recognition algorithm. Its primary oracle uses bitset component
search in each induced graph/complement. The independent reference first
checks the induced-`P4` characterization directly, then enumerates all
vertex subsets as modules, extracts the strong-module inclusion tree, and
checks whether each quotient is a disjoint union or complete join. It therefore
uses a different recognition and decomposition route.

The method is distinct from [`chordal_graph_recognition`](../../g/chordal_graph_recognition/README.md),
which recognizes graphs with no induced cycle of length at least four, and
from [`common_interval_decomposition_tree`](../../c/common_interval_decomposition_tree/README.md),
which decomposes common intervals of a permutation rather than arbitrary
graph vertices. It also goes beyond
[`connected_components_of_complement_graph`](../connected_components_of_complement_graph/README.md),
which returns one complement-component partition: this profile validates the
cograph property and serializes the recursive graph/complement decomposition.

## Provenance and rights

The cotree construction is attributed to Corneil, Lerchs, and Stewart
Burlingham, [“Complement Reducible Graphs”](https://doi.org/10.1016/0166-218X(81)90013-5),
*Discrete Applied Mathematics* 3(3), 1981. Recognition and cotree construction
are also studied by Corneil, Perl, and Stewart in [“A Linear Recognition
Algorithm for Cographs”](https://doi.org/10.1137/0214065), *SIAM Journal on
Computing* 14(4), 1985. The publications are used for algorithmic ideas only;
this bounded contract, workload, references, and all ports are clean-room.
See [`RIGHTS.md`](RIGHTS.md).

## Ports and files

[C](../../../c/c/cograph_cotree_decomposition.c) ·
[C3](../../../c3/c/cograph_cotree_decomposition.c3) ·
[C++](../../../cpp/c/cograph_cotree_decomposition.cpp) ·
[Elisa](../../../elisa/c/cograph_cotree_decomposition.elisa) ·
[Mojo](../../../mojo/c/cograph_cotree_decomposition.mojo) ·
[Nim](../../../nim/c/cograph_cotree_decomposition.nim) ·
[Odin](../../../odin/c/cograph_cotree_decomposition.odin) ·
[Rust](../../../rust/c/cograph_cotree_decomposition.rs) ·
[V](../../../v/c/cograph_cotree_decomposition.v) ·
[Zig](../../../zig/c/cograph_cotree_decomposition.zig)

Fixtures are in [`workload.json`](workload.json). The
[component-search primary reference](primary_oracle.py) and
[strong-module independent reference](independent_oracle.py) expose
`expected_output` and `expected_result`. The package-local inventory is
[`verify_workload.py`](verify_workload.py).
