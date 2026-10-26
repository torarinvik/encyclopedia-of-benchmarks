# SAGA-Bench incremental graph analytics

This package captures the insertion-only update path from SAGA-Bench as six selectable, deterministic bounded profiles. The local static BFS, Dijkstra/SSSP, PageRank, connected-components, and widest-path packages compute from a complete graph; this profile starts from supplied prior state, marks endpoints of a new edge batch, and propagates only state changes through the updated graph. The max-computation mode is a related maximum-label variant of connected-component propagation.

## ABI and input

- Exported symbol: `saga_incremental_analytics` (`i64_array_bytes_output`).
- Input: `[mode,n,base_edge_count,added_edge_count,source,property[0..n), then all base and added edges as (u,v,weight)]`.
- Modes: `1` BFS distance, `2` weighted SSSP, `3` PageRank, `4` minimum component label, `5` single-source widest path, `6` maximum component label.
- Graphs are simple, undirected, and insertion-only. Edge endpoints use canonical `u < v`; weights are 1–9. Base edges precede additions in the adjacency order. Both endpoints of every added edge are initially affected.
- Bounds: `2 <= n <= 8`, `0 <= base_edge_count`, `1 <= added_edge_count`, and at most 28 total edges. The exact frame length is `5+n+3*(base_edge_count+added_edge_count)`.
- `source` is a vertex ID for modes 1, 2, and 5; modes 3, 4, and 6 require `source=-1`.
- The property vector is the state before the inserted batch and must be a valid result for the base graph. Alternatively, an all-`-1` vector requests fresh-state initialization and is permitted only when the base graph has no edges. For an initialized state, BFS uses `-1` for unreachable vertices; weighted SSSP uses the profile sentinel `1,000,000,000`; widest paths use zero for unreachable vertices and that same sentinel at the source; CC/MC use the component's minimum/maximum vertex ID; and PageRank uses nonnegative millionths, decoded to binary32. On a fresh state, the source initializes distances, labels, or rank using its mode-specific initialization rules. The ABI checks value ranges but treats this graph-state invariant as a caller precondition.
- Return the final property vector as little-endian signed i64 values; return `8*n` on success, `-1` for invalid input, or `-2` for a null/short output buffer. Errors leave output untouched.

## Update recurrence

The input state represents the graph before the new edge batch. It must be a valid mode-specific state for the base graph or, only when the base graph has no edges, an all-`-1` fresh-state vector. BFS may have individual `-1` entries for vertices unreachable from its source; other mixed initialized/uninitialized states are outside the contract. The ports construct adjacency lists in source insertion order, seed the first frontier with the endpoints of new edges, process active vertices in ascending-ID order for the initial pass, then use FIFO frontier waves with per-wave duplicate suppression. They stop when no active vertices remain. This serial schedule makes the source's frontier recurrence deterministic while preserving its stateful update work.

| Mode | Updated state |
| --- | --- |
| BFS | Pull the minimum reachable neighbor distance plus one; propagate improving distances. The source's first affected pass also relaxes outgoing neighbors immediately. |
| SSSP | Pull the minimum neighbor distance plus edge weight; propagate strict decreases. |
| PageRank | Recompute affected ranks from incoming contributions, then propagate vertices whose binary32 rank changes by more than `1e-7`. Contributions are snapshotted once per frontier wave. |
| CC | Propagate the minimum vertex label across the newly connected undirected component. |
| SSWP | Propagate the maximum over `min(neighbor_label, edge_weight)`; this is max-min widest-path repair. |
| MC | Propagate the maximum vertex label across the newly connected component. This is the source's separate maximum-computation operation, related to CC but with the opposite label extremum. |

PageRank requires every vertex to have nonzero degree after insertion, matching the source kernel's unguarded `rank/out_degree` calculation. The contract omits graph-file parsing, data-structure variants, OpenMP races/scheduling, logging, CSV timing, and recomputation-from-scratch modes. The recurrence is run to its frontier stopping condition with a 256-wave safety bound.

## Source and rights

Behavior is based on SAGA-Bench commit [`de61f442b39ffecd8630adc4cb1e39569d0d90cc`](https://github.com/abasak24/SAGA-Bench/tree/de61f442b39ffecd8630adc4cb1e39569d0d90cc): `src/dynamic/dyn_bfs.h::dynBFSAlg`, `dyn_sssp.h::dynSSSPAlg`, `dyn_pr.h::dynPRAlg`, `dyn_cc.h::dynCCAlg`, `dyn_sswp.h::dynSSWPAlg`, and `dyn_mc.h::dynMCAlg`; edge endpoint marking comes from `src/dynamic/adListShared.h::processMetaData`. The repository root declares the Simplified BSD 2-Clause License, copied in full to [`LICENSE.txt`](LICENSE.txt). These ports are clean-room implementations of the incremental routines; the SAGA README notes that most recomputation routines are borrowed from GAP Benchmark Suite, and those routines are outside this package.

## Files

- Workload fixtures: [`workload.json`](workload.json)
- Independent Python oracle: [`saga_incremental_analytics_oracle.py`](../../saga_incremental_analytics_oracle.py)
- Nine language ports: `c/s`, `c3/s`, `cpp/s`, `elisa/s`, `nim/s`, `odin/s`, `rust/s`, `v/s`, and `zig/s`.
