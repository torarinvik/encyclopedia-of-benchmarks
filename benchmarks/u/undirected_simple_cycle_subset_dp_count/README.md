# Undirected simple-cycle counting by subset DP

Count every simple cycle of length at least three in a simple undirected graph,
once regardless of its starting vertex or traversal direction.

## Contract

The `i64_array_scalar` input is `[n,m,(u,v)*m]`, with zero-based IDs,
`1<=n<=14`, and `0<=m<=n(n-1)/2`. Every edge is encoded with `u<v`, and the
edge pairs must be strictly lexicographically increasing. This pins duplicate
and edge-order semantics. A valid frame contains at most 184 words; up to 185
words are parseable so a single trailing word can be rejected. Malformed or
null input returns `-1`. The exact cycle count fits signed 64-bit output.

## Primary method

For each vertex subset `S`, its least-numbered vertex is the only allowed
start. `dp[S][v]` counts paths from that start to endpoint `v` that visit
exactly `S`; the singleton state starts with one path. A transition appends an
unused neighbor greater than the start. When `|S|>=3` and `v` is adjacent to
the start, the path closes into a cycle. The DP sums both directions for each
cycle, so the final oriented total is divided by two. This counts cycles of
every length without counting rotations or reversed traversals separately.

The recurrence takes `O(2^n (n+m))` time and `O(n 2^n)` words of working
storage. The independent reference uses DFS, fixes the least cycle vertex,
and accepts only the orientation whose second vertex is smaller than its last
vertex. The workload includes triangles, chorded graphs, disconnected cycle
components, a complete eight-vertex graph, maximum-vertex sparse input, and
malformed frames.

This differs from [`gbbs_five_cycle_count`](../../g/gbbs_five_cycle_count/README.md),
which counts only five-cycles; [`directed_simple_cycles`](../../d/directed_simple_cycles/README.md),
which enumerates directed cycles and returns lists; and minimum-cycle or
cycle-basis packages, which optimize a weight or construct a basis rather
than count all undirected cycles.

See [`RIGHTS.md`](RIGHTS.md) for provenance. The package-local static
[`verify_workload.py`](verify_workload.py) compares fixture outputs with both
references and checks source inventory without invoking native ports.

## Ports

| Language | Source |
|---|---|
| C | `c/u/undirected_simple_cycle_subset_dp_count.c` |
| C3 | `c3/u/undirected_simple_cycle_subset_dp_count.c3` |
| C++ | `cpp/u/undirected_simple_cycle_subset_dp_count.cpp` |
| Elisa | `elisa/u/undirected_simple_cycle_subset_dp_count.elisa` |
| Mojo | `mojo/u/undirected_simple_cycle_subset_dp_count.mojo` |
| Nim | `nim/u/undirected_simple_cycle_subset_dp_count.nim` |
| Odin | `odin/u/undirected_simple_cycle_subset_dp_count.odin` |
| Rust | `rust/u/undirected_simple_cycle_subset_dp_count.rs` |
| V | `v/u/undirected_simple_cycle_subset_dp_count.v` |
| Zig | `zig/u/undirected_simple_cycle_subset_dp_count.zig` |
