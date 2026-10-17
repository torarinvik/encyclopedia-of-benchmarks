# Stoer–Wagner global minimum cut

Compute the global minimum cut of a small undirected weighted graph with the deterministic Stoer–Wagner contraction algorithm.

## Contract

The i64_array_scalar input is [n, row-major adjacency matrix], with n from 2 through 16 and exactly 1+n*n signed 64-bit values. The matrix must be symmetric, have a zero diagonal, and contain integer edge weights in 0..1,000,000. Invalid shape or values return -1. A disconnected graph is valid and returns a minimum cut of 0.

The output is the minimum total weight of edges crossing any nontrivial vertex partition. At n=16, the total undirected edge weight is at most 120,000,000, so all phase weights and contraction sums fit signed 32-bit arithmetic as they do in the pinned Java source.

Each phase grows a set by repeatedly selecting the unmerged vertex with the greatest accumulated connection weight. The implementation scans vertex indices in ascending order and replaces the current choice only on a strict increase, preserving the source's deterministic lower-index tie behavior. It records the final selected vertex's weight as that phase's cut, then merges that vertex into the preceding one. The algorithm takes O(n^3) time and O(n^2) space.

The independent oracle enumerates all nontrivial cuts while fixing vertex 0 to one side, so it does not reuse the contraction algorithm. This benchmark is distinct from randomized Karger min-cut; the unrelated local minimum_cut candidate has an invalid source.

## Pinned source

The source is Java StoerWagner.findMinCut at [TheAlgorithms/Java commit e43ec3897e48f23843972d02cd05a5bb1b6864a2](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/StoerWagner.java).

## Workload

See [workload.json](workload.json) for two-vertex, weighted, tied, disconnected, zero-weight, maximum-dimension, and invalid matrix cases. The independent oracle is [benchmarks/stoer_wagner_oracle.py](../../stoer_wagner_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/stoer_wagner.c](../../../c/s/stoer_wagner.c) |
| C3 | [c3/s/stoer_wagner.c3](../../../c3/s/stoer_wagner.c3) |
| C++ | [cpp/s/stoer_wagner.cpp](../../../cpp/s/stoer_wagner.cpp) |
| Elisa | [elisa/s/stoer_wagner.elisa](../../../elisa/s/stoer_wagner.elisa) |
| Nim | [nim/s/stoer_wagner.nim](../../../nim/s/stoer_wagner.nim) |
| Odin | [odin/s/stoer_wagner.odin](../../../odin/s/stoer_wagner.odin) |
| Rust | [rust/s/stoer_wagner.rs](../../../rust/s/stoer_wagner.rs) |
| V | [v/s/stoer_wagner.v](../../../v/s/stoer_wagner.v) |
| Zig | [zig/s/stoer_wagner.zig](../../../zig/s/stoer_wagner.zig) |
