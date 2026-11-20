# Sugiyama longest-path layer assignment

This package implements the `LongestPath` DAG layer-assignment heuristic from
the layer-assignment phase of the Sugiyama framework. It is a distinct phase
from the existing [`sugiyama_barycentric_crossing_reduction`](../sugiyama_barycentric_crossing_reduction/README.md),
which takes an already layered proper hierarchy and only changes vertex order
within each layer.

## Contract

Input is a signed-i64 array:

    [vertex_count, edge_count, source_0, target_0, ...]

Vertices are numbered `0..vertex_count-1`; edges are directed. The bound is
0–32 vertices and 0–128 edges. Every endpoint must be in range, every directed
edge must be unique, and the graph must be acyclic. Empty graphs are valid.
Malformed input, duplicate edges, or a cycle returns `-1` without writing.

The algorithm repeatedly finds all remaining sinks, assigns that complete
group to the current topmost layer, and removes the sinks and their incident
edges. Sinks found in the same round share a layer. Vertices within a layer
have canonical ascending-ID order. The output uses per-vertex layer IDs, so
vertex IDs are implicit in output positions:

    [layer_count, layer_id_of_vertex_0, ..., layer_id_of_vertex_(n-1)]

For a nonempty graph, sinks occupy layer `layer_count-1` and each edge's
source has a smaller layer ID than its target. Long edges may span multiple
layers; insertion of dummy vertices is outside this package. The empty graph
returns `[0]`.

Output is a little-endian signed-i64 byte array. Its length is
`8*(vertex_count+1)` bytes, at most 264 bytes. A null output or insufficient
capacity returns `-2` without writes. Workspace is bounded at 8,192 bytes.

The primary reference performs the repeated simultaneous sink-removal rounds.
The independent reference first computes a source-first topological order,
then computes longest distances to a sink while traversing that order in
reverse. Both serialize the same per-vertex labels and use the same validation
contract.

## Sources and distinctness

Nikola S. Nikolov, “Sugiyama Algorithm,” *Encyclopedia of Algorithms*,
Chapter 649, DOI [10.1007/978-1-4939-2864-4_649](https://doi.org/10.1007/978-1-4939-2864-4_649),
“Key Results,” layer-assignment discussion. The chapter names the Longest Path
heuristic, its sink-layer sequence, and minimum-height property, citing
Kurt Mehlhorn, *Data Structures and Algorithms 2: Graph Algorithms and
NP-Completeness* (1984), DOI
[10.1007/978-3-642-69897-2](https://doi.org/10.1007/978-3-642-69897-2).
For the explicit sink-removal operational description, see
Hoi-Ming Wong, *Upward Planarization and Layout*, §3.1.2 “Layer Assignment”
(2011), [dissertation PDF](https://eldorado.tu-dortmund.de/server/api/core/bitstreams/e5e22bc5-1910-44e6-a678-910e795ee166/content).

This profile does not include cycle removal, dummy insertion, crossing
reduction, or coordinate assignment. Local topological-sort packages return
an ordering; they do not assign minimum-height sink-distance layers. The
existing barycentric crossing-reduction package starts after layer assignment,
on a supplied proper hierarchy.

## Inventory

The references, fixtures, ports, source notes, and package inventory are
included here. The shared suite registration and global catalog remain a
separate integration step.

| Language | Source |
|---|---|
| C | `c/s/sugiyama_longest_path_layer_assignment.c` |
| C3 | `c3/s/sugiyama_longest_path_layer_assignment.c3` |
| C++ | `cpp/s/sugiyama_longest_path_layer_assignment.cpp` |
| Elisa | `elisa/s/sugiyama_longest_path_layer_assignment.elisa` |
| Mojo | `mojo/s/sugiyama_longest_path_layer_assignment.mojo` |
| Nim | `nim/s/sugiyama_longest_path_layer_assignment.nim` |
| Odin | `odin/s/sugiyama_longest_path_layer_assignment.odin` |
| Rust | `rust/s/sugiyama_longest_path_layer_assignment.rs` |
| V | `v/s/sugiyama_longest_path_layer_assignment.v` |
| Zig | `zig/s/sugiyama_longest_path_layer_assignment.zig` |

Primary reference: `benchmarks/s/sugiyama_longest_path_layer_assignment/primary_oracle.py`.
Independent reference: `benchmarks/s/sugiyama_longest_path_layer_assignment/independent_oracle.py`.
