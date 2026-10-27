# Geometric Greedy and Compass Routing

This package profiles two local forwarding rules stated directly in “Routing
in Geometric Networks,” *Encyclopedia of Algorithms*, DOI
10.1007/978-1-4939-2864-4_352: Greedy Routing and Compass Routing. It also
covers those same two algorithm cores discussed in “Geographic Routing,” DOI
10.1007/978-1-4939-2864-4_164. It does not model radio transmission, route
costs, or a theorem about success on a graph class.

## Contract

The ABI is `i64_array_bytes_output`. Input is
`[n, mode, source, target, x[n], y[n], adjacency[n][n]]`. `n` is 2–8,
`mode=0` selects Greedy and `mode=1` Compass, node IDs are zero-based, and
coordinates are distinct integers in `[-8,8]`. The adjacency matrix must be a
simple undirected graph. The maximum input is 84 i64 values.

Greedy forwards to the adjacent node with minimum squared Euclidean distance
to the target, breaking ties by node ID. Compass forwards to the adjacent node
with minimum angle between the current-to-target and current-to-neighbor
vectors. The implementation compares cosines by exact integer cross-products,
then breaks equal angles by node ID. Routing stops at the target, a local
failure, a repeated node, or after visiting all nodes.

The output is a fixed ten-i64 record: `[delivered, hop_count, path[8]]`.
`path` starts with the source and contains each distinct visited node, padded
with `-1`; `delivered` is 1 only if the target was reached. The result is 80
bytes. Invalid input returns `-1`; null or undersized output returns `-2`
without writing bytes. Coordinate and ID tie rules are deterministic profile
choices where the chapter leaves ties open.

The chapter also summarizes Greedy-Compass, One-State-Bit, predecessor-aware
DFS, Face Routing, Adaptive Face Routing, and GOAFR+. Those are not included:
the bounded source account does not fully specify compass-neighbor selection,
state-bit transitions for all geometric degeneracies, face markers and
planarization, AFR's geometric bounds/round procedure, or GOAFR+'s fallback
details. They remain distinct algorithms rather than aliases for these two
stateless modes.

## Files

The nine ports are under `c/g`, `cpp/g`, `rust/g`, `c3/g`, `nim/g`, `odin/g`,
`elisa/g`, `v/g`, and `zig/g`. `workload.json` and the two independent Python
oracles specify the bounded input and byte output.
