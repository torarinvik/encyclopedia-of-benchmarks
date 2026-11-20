# k²-tree compact directed graph queries

This bounded profile stores a directed adjacency relation in a recursive
binary k²-tree and answers edge-membership and successor-mask queries through
rank-based navigation over its `T` and `L` bitmaps.

## Contract

The ABI is `i64_array_bytes_output`; the exported symbol is
`k2_tree_compact_graph`. Input is `[N,row_mask[0..N),Q,(opcode,u,v)*]`, with
`1<=N<=32`, `0<=Q<=128`, and exact length `N+2+3Q`. Row `u` contains an edge
to `v` iff bit `v` is set in `row_mask[u]`. Self-loops are allowed. A row mask
must be in `[0,2^N)`. Opcode 0 queries edge membership `(u,v)`; opcode 1 asks
for all successors of `u`, and requires the unused `v` field to be zero.
Malformed or null input returns `-1`. A null output or insufficient output
capacity returns `-2` without writing.

Output is a little-endian signed-i64 vector `[Q,result[0..Q))`. An edge query
returns zero or one. A successor query returns an N-bit mask whose bit `v` is
set exactly when `u->v` exists. Success returns the bytes written. The
maximum valid input is 418 words, the one-extra-word parseable frame is 419
words, and output is at most 1,032 bytes.

## k²-tree profile

The row masks are only the input encoding of the graph. The primary method
reconstructs the succinct tree and answers queries from it; it does not answer
queries directly from those masks. Pad the N-by-N relation with zero rows and
columns to `S x S`, where `S` is the least power of two at least
`max(N,2)`. Split each region into four quadrants in row-major order
(top-left, top-right, bottom-left, bottom-right). A region bit is one exactly
when that region contains at least one edge.

The `T` bitmap stores breadth-first region bits before the final cell level;
`L` stores the final cell bits under nonempty parent regions. Both bitmaps
pack bit index `i` into the least-significant-first position `i mod 8` of byte
`floor(i/8)`. The root is implicit. A zero region bit ends a failed edge
query immediately.

The primary builds a u16 prefix table over `T` where `rank_prefix[i+1]` is the
number of one bits in `T[0..i]`. For a node at `T` index `x`, its child group
starts at `4*rank_prefix[x+1]`; the implicit root's child group starts at zero.
The next quadrant is selected from the current row and column bits. Once the
child position reaches `L`, its bit answers the edge query. A successor query
repeats that rank-based membership traversal for each of the at most 32
candidate columns and returns the resulting bit mask. The independent oracle
checks row masks directly without constructing a tree.

For `S<=32`, `T` has at most 340 bits and `L` at most 1,024 bits. The primary
uses packed `T` and `L` arrays (43 and 128 bytes), a 341-entry u16 rank-prefix
array (682 bytes), and four 256-byte coordinate arrays for breadth-first
construction. Fixed storage is 1,877 bytes; the declared workspace cap is
4,096 bytes, excluding input and output. Construction checks at most 1,364
child regions, with at most 1,984 row-mask probes; edge lookup follows at most
five levels, and successor lookup checks at most 32 columns.

The workload covers the minimum padded graph, a non-power-of-two graph,
empty relations, self-loops, membership and successor queries, a maximum
418-word input with 128 queries and 1,032-byte output, malformed framing and
fields, null input/output, and insufficient capacity. See
[`workload.json`](workload.json), [`RIGHTS.md`](RIGHTS.md), and
[`INVENTORY.md`](INVENTORY.md).

## Provenance and implementations

NIST DADS identifies the k²-tree as a compact directed-graph representation
and links it to Brisaboa, Ladra, and Navarro's operational description. The
ports implement the algorithmic ideas independently; no source code, paper
prose, or published examples are copied.

| Language | Source |
|---|---|
| C | [`c/k/k2_tree_compact_graph.c`](../../../c/k/k2_tree_compact_graph.c) |
| C3 | [`c3/k/k2_tree_compact_graph.c3`](../../../c3/k/k2_tree_compact_graph.c3) |
| C++ | [`cpp/k/k2_tree_compact_graph.cpp`](../../../cpp/k/k2_tree_compact_graph.cpp) |
| Elisa | [`elisa/k/k2_tree_compact_graph.elisa`](../../../elisa/k/k2_tree_compact_graph.elisa) |
| Mojo | [`mojo/k/k2_tree_compact_graph.mojo`](../../../mojo/k/k2_tree_compact_graph.mojo) |
| Nim | [`nim/k/k2_tree_compact_graph.nim`](../../../nim/k/k2_tree_compact_graph.nim) |
| Odin | [`odin/k/k2_tree_compact_graph.odin`](../../../odin/k/k2_tree_compact_graph.odin) |
| Rust | [`rust/k/k2_tree_compact_graph.rs`](../../../rust/k/k2_tree_compact_graph.rs) |
| V | [`v/k/k2_tree_compact_graph.v`](../../../v/k/k2_tree_compact_graph.v) |
| Zig | [`zig/k/k2_tree_compact_graph.zig`](../../../zig/k/k2_tree_compact_graph.zig) |

The primary Python reference models packed `T`/`L` plus rank-prefix queries;
the independent reference uses direct row-mask tests. Package-local static
inventory and workload reconciliation helpers are present but have not been
run.
