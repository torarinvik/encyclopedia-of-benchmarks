# Euler Tour Tree

Maintain a dynamic forest under edge links, edge cuts, vertex-weight updates,
and component queries. A component query returns its vertex count and the sum
of its vertex weights.

Each component is stored as a cyclic Euler tour in an implicit treap. A vertex
appears once as a marker; each undirected edge appears as a pair of directed
arc nodes. To link two components, rotate each tour to the requested endpoint
and join both tours with the new arc pair. To cut an edge, rotate to one of its
arcs, split the sequence around both arcs, and retain the two remaining tours.
Treap subtree aggregates track marker count and marker-weight sum. This is a
dynamic forest representation distinct from [`link_cut_tree`](../../l/link_cut_tree/README.md),
which maintains preferred paths for path operations.

## Bounded contract

The `i64_array_bytes_output` entry point is
`euler_tour_tree(input, length, output, capacity)`. Input is
`[N,M,weights[N],then M tagged operations]`, with `1<=N<=8`, `1<=M<=32`, and
weights in `[-100,100]`. Operations are `[0,u,v]` to link disconnected
vertices, `[1,u,v]` to cut an existing edge, `[2,vertex,new_weight]` to assign
a vertex weight, or `[3,vertex]` to query that vertex's component. All indices
are zero-based. A query emits two little-endian signed 64-bit integers: vertex
count followed by weight sum. At least one query is required.

Malformed framing, out-of-range values, a cycle-forming link, or a cut of a
missing edge returns `-1`. Valid input with a null or undersized output buffer
returns `-2`; errors leave output unchanged. The maximum valid input length is
105 words; the parser accepts up to 106 words to reject a trailing-word frame.
Output is at most 512 bytes, and fixed workspace is 16384 bytes.

The primary oracle uses an implicit treap Euler-tour representation. The
independent oracle maintains explicit adjacency sets and discovers each
queried component with a graph traversal. The bounded profile has at most 72
tour nodes and at most 32 operations.

[`workload.json`](workload.json) records the operation contract and fixtures.
[`verify_workload.py`](verify_workload.py) checks fixture/oracle agreement,
provenance, and the ten source paths; it has not been run.

## Provenance and rights

The algorithm was identified from OI Wiki's
[Euler Tour Tree article](https://en.oi-wiki.org/ds/ett/), which states CC
BY-SA 4.0 and SATA terms. The bounded interface, workload, fixtures, oracles,
documentation, and implementations are clean-room work. No upstream code or
article prose was copied. See [`RIGHTS.md`](RIGHTS.md).

## Implementations

| Language | Source |
|---|---|
| C | [`c/e/euler_tour_tree.c`](../../../c/e/euler_tour_tree.c) |
| C3 | [`c3/e/euler_tour_tree.c3`](../../../c3/e/euler_tour_tree.c3) |
| C++ | [`cpp/e/euler_tour_tree.cpp`](../../../cpp/e/euler_tour_tree.cpp) |
| Elisa | [`elisa/e/euler_tour_tree.elisa`](../../../elisa/e/euler_tour_tree.elisa) |
| Mojo | [`mojo/e/euler_tour_tree.mojo`](../../../mojo/e/euler_tour_tree.mojo) |
| Nim | [`nim/e/euler_tour_tree.nim`](../../../nim/e/euler_tour_tree.nim) |
| Odin | [`odin/e/euler_tour_tree.odin`](../../../odin/e/euler_tour_tree.odin) |
| Rust | [`rust/e/euler_tour_tree.rs`](../../../rust/e/euler_tour_tree.rs) |
| V | [`v/e/euler_tour_tree.v`](../../../v/e/euler_tour_tree.v) |
| Zig | [`zig/e/euler_tour_tree.zig`](../../../zig/e/euler_tour_tree.zig) |

Root owns shared suite registration and benchmark-corpus wiring.
