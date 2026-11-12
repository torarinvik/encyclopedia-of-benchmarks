# Dynamic top-tree component diameter

Maintain nonnegative edge weights on a fixed tree and report the tree's
weighted diameter after selected point updates. The cluster algebra follows
the rake/compress top-tree description in the
[OI Wiki Top Tree chapter](https://oi-wiki.org/ds/top-tree/), including its
dynamic-diameter example. Implementations here are clean-room and use a
bounded, balanced cluster hierarchy built once for each call.

## Input and ABI

The exported C ABI symbol is
`dynamic_top_tree_component_diameter(const int64_t *input, size_t length,
uint8_t *output, size_t capacity)` using `i64_array_bytes_output`.

Input is the signed 64-bit array:

```text
[N, Q, (u, v, w) repeated N-1 times, (opcode, edge_id, value) repeated Q times]
```

`1 <= N <= 16`, `0 <= Q <= 32`. The `N-1` initial edges, in input order,
must form a connected tree. Vertices and edge IDs are zero-based. Initial edge
weights and replacement weights are in `0..=1000`.

Each operation has three words:

- `[0, edge_id, new_weight]` replaces that edge's weight.
- `[1, 0, 0]` queries the diameter of the whole tree.

The output contains one signed 64-bit diameter per query, in operation order,
encoded as little-endian bytes. Its maximum size is 256 bytes. A successful
call returns the number of bytes written. Malformed framing, a non-tree edge
list, invalid fields, or an unknown opcode returns `-1`. A null output pointer
or insufficient capacity returns `-2` when at least one answer is required.
Answers are staged before copying, so errors leave the caller's output buffer
untouched. A valid trace with no query may use a null output pointer and
returns zero. The fixed workspace bound is 16384 bytes, allowing for the fixed cluster arena and per-call working tables across the supported language representations.

## Rake/compress hierarchy

Every edge starts as a base cluster storing its path length, farthest distance
from each endpoint, and diameter. A rake cluster stores the two largest arms
at its shared vertex and the best diameter among its branches. Raking a leaf
joins its edge cluster and local rake cluster into one branch. Compressing a
degree-two vertex joins its two incident edge clusters and its local rake
cluster, preserving the two outside endpoints. Each level rakes current leaves
and compresses a maximal independent set of degree-two vertices; rake branches
are combined by balanced binary merges. This produces a bounded balanced
hierarchy with at most 75 summary nodes.

The hierarchy is built once. An edge-weight update changes one base cluster
and recalculates only its parent chain. A query reads the diameter stored in
the root rake cluster. Construction takes `O(N^2 log N)` time with the fixed
adjacency-table builder; updates take `O(log^2 N)` worst-case summary work for
the bounded balanced hierarchy, queries take `O(1)`, and fixed storage is
`O(N^2)`. At `N <= 16`, the maximum possible diameter is 15,000.

The primary oracle builds and updates the same rake/compress cluster hierarchy.
The independent oracle ignores cluster summaries and traverses the tree from
every vertex to compute all-pairs distances directly.

## Source and ports

The cluster operations and dynamic-diameter summary follow the OI Wiki
[`Top Tree`](https://oi-wiki.org/ds/top-tree/) chapter. OI Wiki text is
licensed CC BY-SA 4.0 with the SATA addition. This package uses the algorithm
description only; it does not copy the article's code. See [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [`c/d/dynamic_top_tree_component_diameter.c`](../../../c/dynamic_top_tree_component_diameter.c) |
| C3 | [`c3/d/dynamic_top_tree_component_diameter.c3`](../../../c3/d/dynamic_top_tree_component_diameter.c3) |
| C++ | [`cpp/d/dynamic_top_tree_component_diameter.cpp`](../../../cpp/d/dynamic_top_tree_component_diameter.cpp) |
| Elisa | [`elisa/d/dynamic_top_tree_component_diameter.elisa`](../../../elisa/d/dynamic_top_tree_component_diameter.elisa) |
| Mojo | [`mojo/d/dynamic_top_tree_component_diameter.mojo`](../../../mojo/d/dynamic_top_tree_component_diameter.mojo) |
| Nim | [`nim/d/dynamic_top_tree_component_diameter.nim`](../../../nim/d/dynamic_top_tree_component_diameter.nim) |
| Odin | [`odin/d/dynamic_top_tree_component_diameter.odin`](../../../odin/d/dynamic_top_tree_component_diameter.odin) |
| Rust | [`rust/d/dynamic_top_tree_component_diameter.rs`](../../../rust/d/dynamic_top_tree_component_diameter.rs) |
| V | [`v/d/dynamic_top_tree_component_diameter.v`](../../../v/d/dynamic_top_tree_component_diameter.v) |
| Zig | [`zig/d/dynamic_top_tree_component_diameter.zig`](../../../zig/d/dynamic_top_tree_component_diameter.zig) |

The workload is in [`workload.json`](workload.json). The primary and
independent oracle modules are
[`dynamic_top_tree_component_diameter_oracle.py`](../../dynamic_top_tree_component_diameter_oracle.py)
and
[`independent_oracle.py`](independent_oracle.py).
The package-local static inventory and fixture checker is
[`verify_workload.py`](verify_workload.py); it has not been run.
