# Thorup–Zwick k=2 approximate distance oracle

This bounded profile implements the sampling hierarchy, per-vertex bunch preprocessing, and alternating bunch-query rule described in Encyclopedia of Algorithms Chapters 568 and 571. It supplies the level-1 sample set as an explicit bit mask so a run is deterministic. One supplied realization does not demonstrate the randomized expected-stretch guarantee.

## Contract

Input is `[n, m, A1_mask, (u, v, weight)[m], q, (source, target)[q]]`. The graph is simple, connected, undirected, and has positive integer edge weights. Bounds are `1 <= n <= 12`, `0 <= m <= 66`, weights `1..1000`, and `0 <= q <= 32`. The mask is nonzero and has no bits at indices `n` or above. Each edge is encoded once with `u < v`; duplicate pairs and self-edges are rejected. Queries use zero-based vertex IDs.

The hierarchy is `A0=V`, `A1={v | mask bit v is set}`, and `A2=empty`, giving k=2. For each vertex, the profile chooses its nearest A1 vertex by `(distance, vertex ID)`. Its bunch contains every A1 vertex and each non-A1 vertex strictly closer than that vertex's nearest A1 distance. A query starts at level 0, checks whether `p_i(target)` is in the current source's bunch, returns `d(source,p_i(target))+d(target,p_i(target))` on success, and otherwise swaps the endpoints and advances to level 1. Distances and ties are exact integer operations.

The byte output is little-endian signed i64 words `[q, estimate_0, ...]`. The input limit is 266 words, output limit is 264 bytes, and fixed workspace is bounded at 2,048 bytes. Malformed or disconnected input returns `-1`; a null output or insufficient capacity on valid input returns `-2`. The implementation stages all output before writing, so errors write no bytes. Validation takes precedence over output-pointer and capacity checks.

The source chapters also discuss faster query variants, constant-time hybrid oracles, and sparse-graph structures. This package covers only the standard Thorup–Zwick k=2 hierarchy and linear bunch query. Chapter 571's Pătrașcu–Roditty oracle and other sparse-graph variants remain outside scope.

## Provenance and rights

The algorithm was implemented independently from the mathematical description in the supplied Encyclopedia of Algorithms EPUB: Chapter 568, DOI `10.1007/978-1-4939-2864-4_568`, and Chapter 571, DOI `10.1007/978-1-4939-2864-4_571`. No book prose, pseudocode image, or implementation code is reproduced. These ports are clean-room implementations of the described algorithm; the book remains under its publisher's copyright.

## Files

- Workload: [`workload.json`](workload.json)
- Rights note: [`RIGHTS.md`](RIGHTS.md)
- Primary oracle: [`thorup_zwick_distance_oracle_oracle.py`](../../thorup_zwick_distance_oracle_oracle.py)
- Independent verifier oracle: [`thorup_zwick_distance_verifier_oracle.py`](../../thorup_zwick_distance_verifier_oracle.py)
- Ports: `c/t/thorup_zwick_distance_oracle.c`, `c3/t/thorup_zwick_distance_oracle.c3`, `cpp/t/thorup_zwick_distance_oracle.cpp`, `elisa/t/thorup_zwick_distance_oracle.elisa`, `nim/t/thorup_zwick_distance_oracle.nim`, `odin/t/thorup_zwick_distance_oracle.odin`, `rust/t/thorup_zwick_distance_oracle.rs`, `v/t/thorup_zwick_distance_oracle.v`, and `zig/t/thorup_zwick_distance_oracle.zig`.
