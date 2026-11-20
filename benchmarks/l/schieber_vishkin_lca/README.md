# Schieber–Vishkin Lowest Common Ancestor

This package answers a batch of lowest-common-ancestor queries on a rooted
undirected tree. It uses Schieber and Vishkin's preorder inlabels, ascendant
bitsets, and vertical-run path jumps. Its query kernel differs from the local
binary-lifting, Tarjan offline DSU, and Farach–Colton–Bender Euler-tour RMQ
profiles.

## Contract

The exported symbol is `schieber_vishkin_lca` with ABI
`i64_array_bytes_output`. Input is
`[node_count, root_id, edge_count, query_count, (edge_u, edge_v)*,
(query_u, query_v)*]`. Vertex IDs are zero-based. The node count is 1..256,
the edge count is exactly `node_count - 1`, and the query count is 0..1024.
The edge pairs must describe one connected acyclic undirected tree. The root
and every query endpoint must be a valid vertex ID.

The output has one byte per query, in query order. Each byte stores the LCA
vertex ID; this fits because IDs are at most 255. A successful call returns
the number of bytes written. Invalid framing, ranges, IDs, duplicate/cyclic
edges, or a disconnected graph return `-1`. A valid nonempty batch with null
or undersized output returns `-2`. Errors leave output untouched. A zero
query batch returns zero and accepts null output. In particular, `n=1` with
no edges is valid, and every `(0,0)` query returns byte zero.

The largest valid input is 2,562 signed 64-bit words. The one-word trailing
frame probe has length 2,563. Output is at most 1,024 bytes. The fixed logical
scratch limit is 32,768 bytes, including staged answers and excluding caller
buffers.

## Schieber–Vishkin method

An iterative DFS assigns preorder labels `pre(v)` from 1 through `n`. Set
`I(v)=pre(v)`, then process vertices in reverse preorder. For each child `c`,
replace `I(parent(c))` with `I(c)` when `lsb(I(c))` is larger. Here
`lsb(x)=x & -x`. Vertices with a common inlabel form a vertical run.

In preorder, compute `A(root)=lsb(I(root))` and
`A(v)=A(parent(v)) | lsb(I(v))`. Store a path-parent value at each preorder
position: the root position maps to the root; when a vertex starts a new run,
its position maps to its parent; otherwise it inherits the parent's stored
value.

For a query `(u,v)`, let `lu=lsb(I(u))`, `lv=lsb(I(v))`, and
`mask=highbit((I(u) xor I(v)) | lu | lv)-1`, where `highbit` returns the
highest set power of two. Select
`j=lsb(A(u) & A(v) & ~mask)`. If `j` differs from an endpoint's inlabel low
bit, use the highest lower set bit in that endpoint's ascendant mask and its
preorder label to index the stored path-parent table. The two resulting
vertices are on the target vertical run; the one with smaller preorder is
the LCA. The implementation uses a fixed number of bit operations and table
accesses per query.

Preprocessing takes `O(n)` time and storage. Each query takes `O(1)` time in
the bounded word-RAM profile, so a batch takes `O(n+q)` time. Fixed storage
includes adjacency, traversal order and stack, labels, ascendant masks,
path-parent entries, and staged answer bytes.

## Sources and ports

The primary source is Schieber and Vishkin, “On Finding Lowest Common
Ancestors: Simplification and Parallelization,” *SIAM Journal on Computing*
17(6), 1253–1262 (1988), [DOI 10.1137/0217079](https://doi.org/10.1137/0217079).
An operational derivation is in Volker Heun's *Algorithmische Bioinformatik:
Bäume und Graphen*, section 4.2, [lecture notes PDF](https://www.bio.ifi.lmu.de/mitarbeiter/volker-heun/notes/as9.pdf).
Schieber's “Parallel Lowest Common Ancestor Computation,” chapter 6 of
*A Synthesis of Parallel Algorithms* (1994), is listed on the
[author's publications page](https://sbarnjit.github.io/).

RosettaCodeData's pinned popular-task index supplied title-only discovery
and the visible score 21. No task prose, solutions, examples, tests, or
fixtures were used. See [RIGHTS.md](RIGHTS.md) and [INVENTORY.md](INVENTORY.md).

| Language | Port |
|---|---|
| C | [`c/l/schieber_vishkin_lca.c`](../../../c/l/schieber_vishkin_lca.c) |
| C3 | [`c3/l/schieber_vishkin_lca.c3`](../../../c3/l/schieber_vishkin_lca.c3) |
| C++ | [`cpp/l/schieber_vishkin_lca.cpp`](../../../cpp/l/schieber_vishkin_lca.cpp) |
| Elisa | [`elisa/l/schieber_vishkin_lca.elisa`](../../../elisa/l/schieber_vishkin_lca.elisa) |
| Mojo | [`mojo/l/schieber_vishkin_lca.mojo`](../../../mojo/l/schieber_vishkin_lca.mojo) |
| Nim | [`nim/l/schieber_vishkin_lca.nim`](../../../nim/l/schieber_vishkin_lca.nim) |
| Odin | [`odin/l/schieber_vishkin_lca.odin`](../../../odin/l/schieber_vishkin_lca.odin) |
| Rust | [`rust/l/schieber_vishkin_lca.rs`](../../../rust/l/schieber_vishkin_lca.rs) |
| V | [`v/l/schieber_vishkin_lca.v`](../../../v/l/schieber_vishkin_lca.v) |
| Zig | [`zig/l/schieber_vishkin_lca.zig`](../../../zig/l/schieber_vishkin_lca.zig) |

Fixtures are in [`workload.json`](workload.json). The primary source-shaped
reference and independent binary-lifting reference are
[`schieber_vishkin_lca_oracle.py`](../../schieber_vishkin_lca_oracle.py) and
[`schieber_vishkin_lca_independent_oracle.py`](../../schieber_vishkin_lca_independent_oracle.py).
The package-local [`check_inventory.py`](check_inventory.py) checks only source
paths and metadata and never launches a benchmark. [`verify_workload.py`](verify_workload.py)
compares the hand-authored fixtures with the two Python references and checks
the ten source files; it never launches a language port. Neither checker has
been run.
