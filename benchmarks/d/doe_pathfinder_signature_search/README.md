# DOE PathFinder Ordered-signature Search

This package captures the ordered-label path search used by the DOE PathFinder
mini-application. Given a directed graph and a label signature, it determines
whether some path starts at a node carrying the first label and visits each
remaining signature label in order. Intervening nodes may have any label, and
the graph may contain cycles.

The search follows the source's modified depth-first structure: at each node it
first tries outgoing edges carrying the next signature label, then explores
outgoing edges while keeping the current target label. Each new signature leg
gets a fresh visited set, so a path may revisit nodes after consuming a label.
When an edge matches the next label, the search may try to consume that label
or continue searching past it if the later signature cannot be completed.

This is distinct from local Dijkstra, A*, and ordinary graph-path searches:
those do not require a path to consume an ordered sequence of node labels with
cycle state reset at each signature leg.

## Contract

The signed 64-bit input array is
`[node_count, edge_count, signature_length, (from, to)*edge_count, node_labels..., signature_labels...]`.
It contains 1–10 nodes, 0–100 directed edges, and a signature of 2–4 labels.
Edges are ordered as supplied, may include self-loops, and must be unique.
Each node has one label in `-1..7`, where `-1` means unlabeled; signature
labels are in `0..7`. The packed length must be exactly
`3 + 2*edge_count + node_count + signature_length`.

The function returns 1 if any qualifying path exists, 0 if none exists, and -2
for malformed input. The bounded profile exposes one signature per call. It
does not parse PathFinder's adjacency-list/configuration files, enumerate all
label pairs, or emit its path/statistics/YAML output. The four-label cap keeps
the source-style backtracking workload bounded.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm doe_pathfinder_signature_search --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/d/doe_pathfinder_signature_search/rust/build.json
```

The independent state-space oracle is [`doe_pathfinder_signature_search_oracle.py`](../../doe_pathfinder_signature_search_oracle.py), and the static cases are in [`workload.json`](workload.json).

## Provenance and license

The source is [`DOE_ProxyApps_C/Pathfinder`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/DOE_ProxyApps_C/Pathfinder), pinned at commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its launcher runs exhaustive
search on `medsmall1.adj_list`. The `searchAlgorithms.c` header attributes
copyright to Sandia Corporation (2013), states that the U.S. Government retains
certain rights under Contract DE-AC04-94AL85000, and licenses PathFinder under
LGPL-3.0-or-later. The pinned tree includes both `COPYING` (GPL-3.0) and
`COPYING.LESSER`; the source headers identify LGPL-3.0-or-later as the license
for PathFinder. The ported core is an independent implementation of the
documented search contract and does not copy upstream source or comments.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/doe_pathfinder_signature_search.c`](../../../c/d/doe_pathfinder_signature_search.c) |
| C3 | [`c3/d/doe_pathfinder_signature_search.c3`](../../../c3/d/doe_pathfinder_signature_search.c3) |
| C++ | [`cpp/d/doe_pathfinder_signature_search.cpp`](../../../cpp/d/doe_pathfinder_signature_search.cpp) |
| Elisa | [`elisa/d/doe_pathfinder_signature_search.elisa`](../../../elisa/d/doe_pathfinder_signature_search.elisa) |
| Nim | [`nim/d/doe_pathfinder_signature_search.nim`](../../../nim/d/doe_pathfinder_signature_search.nim) |
| Odin | [`odin/d/doe_pathfinder_signature_search.odin`](../../../odin/d/doe_pathfinder_signature_search.odin) |
| Rust | [`rust/d/doe_pathfinder_signature_search.rs`](../../../rust/d/doe_pathfinder_signature_search.rs) |
| V | [`v/d/doe_pathfinder_signature_search.v`](../../../v/d/doe_pathfinder_signature_search.v) |
| Zig | [`zig/d/doe_pathfinder_signature_search.zig`](../../../zig/d/doe_pathfinder_signature_search.zig) |

