# Static inventory

Algorithm: `sugiyama_longest_path_layer_assignment` (Chapter 649,
sink-removal longest-path layer assignment).

| Artifact | Path |
|---|---|
| Workload | `workload.json` |
| Primary oracle | `primary_oracle.py` |
| Independent oracle | `independent_oracle.py` |
| Provenance and rights | `RIGHTS.md` |
| Contract and source inventory | `README.md` |
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

The byte ABI exports `sugiyama_longest_path_layer_assignment` in every port.
Input is `[n,m,(u,v)*m]`; output is signed-i64 little-endian
`[layer_count, layer_id_by_vertex_id]`. The output bounds are at most 264
bytes and the workload includes empty/singleton graphs, unequal path lengths,
disconnected components, same-layer ties, duplicate edges, cycles, malformed
input, and output-capacity errors.
