# C-connected clustered embedding condition

This package checks the outer-face characterization of c-planarity for a
supplied c-connected clustered embedding. It does not search for a different
rotation system or construct a drawing.

## Input and result

The scalar ABI accepts signed 64-bit words:

```text
[n,c,outer_u,outer_v,(degree,clockwise_neighbors...)*n,cluster_mask[c]]
```

There are 3 through 8 vertices and at most `n-2` explicit clusters. The root
cluster `V` is implicit. Each explicit mask is a distinct proper subset of at
least two vertices; masks form a laminar family, and every cluster induces a
connected subgraph. The graph is simple and connected. Each vertex row gives
its distinct neighbors in clockwise order. The directed outer dart identifies
the outer face. Face walks use the next clockwise neighbor after the incoming
edge, consistent with the repository's rotation-system convention.

The result is `1` when this supplied embedding satisfies the criterion for
every cluster, `0` when this embedding fails it, and `-1` for malformed,
nonplanar, or non-c-connected input. A zero result says nothing about whether
some other embedding of the same clustered graph could be c-planar. The
largest valid frame has 54 words; 55 words are parseable to classify one
trailing word as invalid. Workspace is bounded to 8,192 bytes.

For each cluster, the primary reference unions faces across every edge not
internal to the cluster. It then checks whether every outside vertex and edge
belongs to the component of the designated outer face in the resulting
induced subembedding. The independent reference instead builds the dual graph
of removed edges and runs a breadth-first search from the outer face.

## Source and scope

Fabrizio Frati, “Clustered Graph Drawing,” *Encyclopedia of Algorithms*,
Chapter 655, [DOI 10.1007/978-1-4939-2864-4_655](https://doi.org/10.1007/978-1-4939-2864-4_655),
Theorem 3. Its cited original theorem is Feng, Cohen, and Eades, “Planarity for
clustered graphs” (1995), [DOI 10.1007/3-540-60313-1_145](https://doi.org/10.1007/3-540-60313-1_145).
The chapter also describes a bottom-up PQ-tree and representative-graph
embedding search for c-connected clustered graphs. This package profiles only
Theorem 3's criterion on one supplied embedding; it does not implement that
PQ-tree search or top-down embedding selection.

The result differs from [`rotation_system_planarity_test`](../r/rotation_system_planarity_test/README.md),
which tests whether a supplied graph rotation system is planar but has no
cluster hierarchy or per-cluster outer-face condition. This package assumes a
rotation system and reports whether that particular clustered embedding meets
the criterion.

See [`RIGHTS.md`](RIGHTS.md) for clean-room provenance. `check_inventory.py`
checks fixture/reference and source inventory consistency without calling any
native port.

## Ports

| Language | Source |
|---|---|
| C | `c/c/c_connected_clustered_embedding_condition.c` |
| C3 | `c3/c/c_connected_clustered_embedding_condition.c3` |
| C++ | `cpp/c/c_connected_clustered_embedding_condition.cpp` |
| Elisa | `elisa/c/c_connected_clustered_embedding_condition.elisa` |
| Mojo | `mojo/c/c_connected_clustered_embedding_condition.mojo` |
| Nim | `nim/c/c_connected_clustered_embedding_condition.nim` |
| Odin | `odin/c/c_connected_clustered_embedding_condition.odin` |
| Rust | `rust/c/c_connected_clustered_embedding_condition.rs` |
| V | `v/c/c_connected_clustered_embedding_condition.v` |
| Zig | `zig/c/c_connected_clustered_embedding_condition.zig` |

All ten ports are clean-room implementations of the bounded criterion. The
workload includes valid and failing supplied embeddings, invalid cluster
families, non-c-connected input, nonplanar rotations, and maximum-frame cases.
