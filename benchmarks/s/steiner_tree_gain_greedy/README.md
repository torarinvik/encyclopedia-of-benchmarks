# Steiner-tree gain-greedy profile

This package implements the chapter's generic gain-greedy recurrence on a
bounded, explicitly supplied family of full components. It is a finite-family
profile of the network Steiner-tree algorithm, not a component generator and
not a claim about the chapter's approximation ratio.

Input is a signed-i64 array:

```text
[vertex_count, terminal_mask, component_count,
 upper-triangle metric weights in (0,1),(0,2),... order,
 component_edge_count, (u,v) edges, ...]
```

There are 2–4 vertices, at least two terminals, at most 4 candidate
components, and weights in `[0,1000]`. The upper-triangle weights define a
complete nonnegative integer metric; triangle inequalities are checked. A
component is supplied as an undirected tree with exactly two or three terminal
leaves and no other leaves. The union of the supplied components must connect
all terminals. Vertices not used by a component are allowed.

At each iteration, eligible components are those whose union with the current
`H` reduces the number of terminal-bearing connected components. For each
eligible `F`, the profile evaluates the chapter's
`gain(H∪F)=mst(P)-mst(P:H∪F)-mst(H∪F)` exactly. `mst(H)` is the minimum spanning
forest of the selected component edges. `mst(P:H)` is computed by contracting
every `H` edge to zero, taking shortest-path distances in the complete metric,
then taking the MST of the resulting terminal-bearing components. The eligible
candidate with greatest gain is selected; ties choose the lower input index.
The chosen component's edges are unioned into `H`. Once all terminals are
connected, the output is the canonical Kruskal minimum spanning tree of `H`,
with edge ties by `(weight,u,v)`.

Output is little-endian signed-i64:

```text
[1, tree_cost, edge_count, (u,v) edges...]
```

The maximum input length is 37 words, maximum output is 72 bytes, and fixed
workspace is 4096 bytes. Invalid input returns `-1`; null output or insufficient
capacity returns `-2` without writes. The profile's supplied candidate family,
progress eligibility rule, deterministic ties, and integer metric bounds are
explicit refinements used to make the source recurrence finite and reproducible.

Source: Weili Wu and Yaocun Huang, “Steiner Trees,” Encyclopedia of Algorithms,
DOI 10.1007/978-1-4939-2864-4_403, `OEBPS/AChap403.html`, Key Results. The
chapter gives the gain definition and greedy choice, and identifies the
full-component families for 3-restricted trees and iterated 1-Steiner. It does
not provide source code or a license grant; these ports are clean-room.

Primary and independent verifier oracles:
`benchmarks/steiner_tree_gain_greedy_oracle.py` and
`benchmarks/steiner_tree_gain_greedy_verifier_oracle.py`.

| Language | Port |
|---|---|
| C | `c/s/steiner_tree_gain_greedy.c` |
| C3 | `c3/s/steiner_tree_gain_greedy.c3` |
| C++ | `cpp/s/steiner_tree_gain_greedy.cpp` |
| Elisa | `elisa/s/steiner_tree_gain_greedy.elisa` |
| Nim | `nim/s/steiner_tree_gain_greedy.nim` |
| Odin | `odin/s/steiner_tree_gain_greedy.odin` |
| Rust | `rust/s/steiner_tree_gain_greedy.rs` |
| V | `v/s/steiner_tree_gain_greedy.v` |
| Zig | `zig/s/steiner_tree_gain_greedy.zig` |
