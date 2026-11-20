# Reverse-delete minimum spanning tree

This package implements Kruskal's reverse-delete construction for a bounded
connected, simple, undirected weighted graph. It starts with every edge and
considers edge IDs in descending `(weight,input_edge_id)` order. An edge is
deleted exactly when the graph remains connected without it.

## Contract

Input is `[n,m,(u,v,w)*m]`, with `2<=n<=8`, `n-1<=m<=20`, endpoints in
`0..n-1`, no self-loops or repeated undirected pairs, and weights in `0..1000`.
The graph must be connected. Input edge orientation is unrestricted; repeated
pairs are rejected regardless of orientation. At most 62 signed-i64 words
form a valid input and 63 words are parseable for the one-extra-word boundary.

The initial retained mask has all `m` low bits set. For each edge in descending
weight and then descending input ID, temporarily clear its bit and run a
connectivity traversal over the remaining edges. Keep it cleared if and only
if every vertex remains reachable from vertex 0. The output is two little-endian
signed-i64 words: the retained edge mask in original input-ID bit positions,
then the sum of retained weights. The result is exactly 16 bytes. Malformed
input returns `-1` before output validation; a null output or capacity below 16
returns `-2` without writing. Fixed native workspace is capped at 2,048 bytes.

For equal-cost MSTs, descending input ID is part of the processing order. The
selected tree therefore retains the lexicographically preferred edge bits in
that descending processing order, with `0` preferred at the first difference.
The exhaustive independent reference pins the same rule without repeating
edge-deletion connectivity: it enumerates all `n-1`-edge subsets, rejects
non-trees, then minimizes total weight and the ordered retained-bit vector.

The primary method takes `O(n*m^2 + m^2)` time: each deletion trial scans the
edge list for every visited vertex, with a separate `O(m^2)` insertion sort.
Its fixed workspace is `O(n+m)`. The independent enumerator
uses `O(C(m,n-1) * (n+m))` time and `O(n+m)` working space. The bounded maxima
are `n=8`, `m=20`, so its exhaustive reference remains finite and small.

## Distinctness and sources

The local Kruskal, Prim, and Borůvka packages grow a forest by adding edges;
this profile starts with the whole graph and prunes edges from heaviest to
lightest after repeated connectivity tests. The local MST classification,
second-best MST, minimum-diameter tree, and geometric MST packages answer
different edge-role or optimization questions. No reverse-delete package or
reservation was found during the local inventory pass. The active
[`bagwell_varray_growth_index`](../../b/bagwell_varray_growth_index/README.md)
package appends to a two-dimensional indexed VArray, so it is unrelated to
edge deletion. Other DADS leads such as move-to-front, interpolation search,
and adaptive Huffman already have local packages and were excluded.

The source-index audit used NIST DADS's [minimum spanning tree entry](https://xlinux.nist.gov/dads/HTML/minimumSpanningTree.html)
and the Codewars [“Make a spanning tree” title](https://www.codewars.com/kata/5ae8e14c1839f14b2c00007a)
to identify the MST family. The Codewars title was discovery metadata only. The
exact reverse-delete method is Construction A'
in Kruskal's 1956 paper, [*On the Shortest Spanning Subtree of a Graph and the
Traveling Salesman Problem*](https://www.cs.yale.edu/homes/lans/readings/routing/kruskal-1956.pdf).
Kleinberg and Tardos independently present the named reverse-delete algorithm
in [Algorithm Design, §4.5](https://www.cs.princeton.edu/~wayne/kleinberg-tardos/pdf/04GreedyAlgorithmsII.pdf).
Only algorithm descriptions were used; no implementation code, problem text,
examples, or tests were copied. See [RIGHTS.md](RIGHTS.md),
[`workload.json`](workload.json), and [INVENTORY.md](INVENTORY.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/r/reverse_delete_mst.c`](../../../c/r/reverse_delete_mst.c) |
| C3 | [`c3/r/reverse_delete_mst.c3`](../../../c3/r/reverse_delete_mst.c3) |
| C++ | [`cpp/r/reverse_delete_mst.cpp`](../../../cpp/r/reverse_delete_mst.cpp) |
| Elisa | [`elisa/r/reverse_delete_mst.elisa`](../../../elisa/r/reverse_delete_mst.elisa) |
| Mojo | [`mojo/r/reverse_delete_mst.mojo`](../../../mojo/r/reverse_delete_mst.mojo) |
| Nim | [`nim/r/reverse_delete_mst.nim`](../../../nim/r/reverse_delete_mst.nim) |
| Odin | [`odin/r/reverse_delete_mst.odin`](../../../odin/r/reverse_delete_mst.odin) |
| Rust | [`rust/r/reverse_delete_mst.rs`](../../../rust/r/reverse_delete_mst.rs) |
| V | [`v/r/reverse_delete_mst.v`](../../../v/r/reverse_delete_mst.v) |
| Zig | [`zig/r/reverse_delete_mst.zig`](../../../zig/r/reverse_delete_mst.zig) |

`check_inventory.py` and `verify_workload.py` expose static inventory and
fixture/reference review APIs. They are included for parent integration and
have not been run.
