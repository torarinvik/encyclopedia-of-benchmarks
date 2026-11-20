# Dense bitset Kosaraju strongly connected components

This profile computes strongly connected components from a dense, packed
adjacency matrix. It uses iterative two-pass Kosaraju. For each vertex, DFS
finds its next unvisited neighbor by intersecting one 64-bit adjacency word
with the corresponding unvisited word. The transpose is built by enumerating
set bits in the input rows. This makes the graph representation and neighbor
discovery part of the workload; the existing edge-list `kosaraju` profile
scans candidate vertex indices individually.

## Contract

Input is `[n, row_words...]`, with `1 <= n <= 256`. Each vertex contributes
`ceil(n/64)` signed i64 values in row-major order. Each value is interpreted as
its unsigned 64-bit bit pattern; bit `j` in a row word denotes the edge to
vertex `64*word+j`. Unused high bits in the last word of every row must be
zero. Self-loops are allowed, and repeated edges are naturally coalesced by
the bitset. The exact valid length is `1 + n*ceil(n/64)`, at most 1025 values;
the parser accepts at most 1026 values so a one-value trailing-frame error is
bounded.

Output is little-endian u16 component count followed by one little-endian u16
component ID for every vertex in ascending vertex order. IDs are canonical:
components are numbered by ascending minimum vertex. The maximum output is
514 bytes. Invalid or null input returns `-1`. Null or undersized output
returns `-2` without writing. The implementation uses at most 32,768 bytes of
scratch storage. Maximum input and output sizes are independent of the SCC
partition.

## Method and bounds

The primary performs iterative Kosaraju. The first pass stores a vertex and a
current row-word cursor per DFS frame. Each step evaluates
`adjacency[v, word] & unvisited[word]`; when nonzero, it clears and pushes one
neighbor, otherwise it advances the cursor. Vertices are appended to finishing
order only after all row words are exhausted. The second pass traverses the
transpose with the same word intersections, marking a neighbor when it is
pushed. A final vertex-order scan remaps temporary component IDs to the
canonical order.

Transpose construction enumerates each set edge once. The two DFS passes scan
at most `ceil(n/64)` words per vertex, in addition to edge enumeration, so the
total time is `O(V*ceil(V/64) + E)` on 64-bit words. The fixed-width lowest-set
bit scan is bounded by 64 shifts. The adjacency and transpose occupy
`2*V*ceil(V/64)` u64 words; at the maximum this is 16,384 bytes. The remaining
word masks, u16 stacks, finishing order, cursors, and component maps use
2,592 bytes, for 18,976 bytes of scratch in total. Output is written directly
to the caller's buffer. In asymptotic bit terms, the packed
matrices use `O(V^2)` bits; in machine-word terms they use
`O(V*ceil(V/64))` words.

The independent reference uses adjacency lists and Tarjan low-link discovery,
then canonicalizes components by minimum vertex. It does not use Kosaraju,
packed-row intersections, or a transpose.

The profile was discovered from Library Checker proposal #1373, which describes
dense SCC input and bitset-based Kosaraju but leaves encoding and scale open.
This package pins a bounded ABI and output contract. Method context is the
iterative packed-row approach in the [cplib-cpp bitset SCC reference](https://hitonanode.github.io/cplib-cpp/graph/strongly_connected_components_bitset.hpp)
and the matrix/transpose approach in [maspypy's bitset SCC reference](https://maspypy.github.io/library/graph/bitset/scc_bitset.hpp).
The [Library Checker proposal](https://github.com/yosupo06/library-checker-problems/issues/1373)
is a discovery index, not a source of code, task text, examples, or fixtures.
See [RIGHTS.md](RIGHTS.md) for provenance notes.

## Ports and inventory

All ten ports implement the same ABI and bounds:

| Language | Source |
|---|---|
| C | [`c/k/kosaraju_dense_bitset_scc.c`](../../../c/k/kosaraju_dense_bitset_scc.c) |
| C3 | [`c3/k/kosaraju_dense_bitset_scc.c3`](../../../c3/k/kosaraju_dense_bitset_scc.c3) |
| C++ | [`cpp/k/kosaraju_dense_bitset_scc.cpp`](../../../cpp/k/kosaraju_dense_bitset_scc.cpp) |
| Elisa | [`elisa/k/kosaraju_dense_bitset_scc.elisa`](../../../elisa/k/kosaraju_dense_bitset_scc.elisa) |
| Mojo | [`mojo/k/kosaraju_dense_bitset_scc.mojo`](../../../mojo/k/kosaraju_dense_bitset_scc.mojo) |
| Nim | [`nim/k/kosaraju_dense_bitset_scc.nim`](../../../nim/k/kosaraju_dense_bitset_scc.nim) |
| Odin | [`odin/k/kosaraju_dense_bitset_scc.odin`](../../../odin/k/kosaraju_dense_bitset_scc.odin) |
| Rust | [`rust/k/kosaraju_dense_bitset_scc.rs`](../../../rust/k/kosaraju_dense_bitset_scc.rs) |
| V | [`v/k/kosaraju_dense_bitset_scc.v`](../../../v/k/kosaraju_dense_bitset_scc.v) |
| Zig | [`zig/k/kosaraju_dense_bitset_scc.zig`](../../../zig/k/kosaraju_dense_bitset_scc.zig) |

[`workload.json`](workload.json) contains bounded valid and malformed fixtures.
[`primary_oracle.py`](primary_oracle.py) mirrors packed iterative Kosaraju;
[`independent_oracle.py`](independent_oracle.py) uses adjacency-list Tarjan.
[`verify_workload.py`](verify_workload.py) is a static package inventory and
fixture/reference checker; it does not compile or execute language ports.
