# Negative cycle detection

This package implements a bounded, clean-room profile of global negative-cycle detection in a weighted directed graph. It is distinct from the local Bellman–Ford shortest-path profiles, which are rooted at a source and report source-reachable behavior.

## Contract

Input is a signed i64 array `[n, m, (u, v, weight)...]`, with `0 ≤ n ≤ 20`, `0 ≤ m ≤ 64`, exact length `2 + 3m`, endpoints in `[0,n)`, and weights in `[-1000,1000]`. Edges are directed; loops and parallel edges are allowed. Initializing every distance to zero models a zero-weight super-source connected to every vertex, so cycles in disconnected components are detected. The implementation performs input-order in-place Bellman–Ford relaxation for `n` passes. A strict relaxation on the last pass signals a negative cycle. The predecessor chain is followed into a cycle, reversed into edge direction, then rotated so its smallest vertex ID comes first.

Output is a sequence of signed i64 values encoded little-endian in bytes. No cycle produces `[0]`; a witness produces `[1, k, v0, ..., v{k-1}]`, where the final vertex has an edge back to `v0` and the sum of the selected directed edges is negative. The cycle is simple and canonicalized by its minimum vertex, while input edge order determines relaxation ties. At most 22 i64 values (176 bytes) are emitted. Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writing.

## Verification

The primary oracle reproduces the specified source-order recurrence and returns exact expected bytes. The independent verifier uses Floyd–Warshall to decide whether any negative cycle exists and checks that a returned witness is a valid negative cycle. It deliberately validates any valid witness rather than requiring the primary oracle's exact witness bytes.

## Provenance and rights

The chapter used to identify the problem is “Negative Cycles in Weighted Digraphs,” in Ming-Yang Kao (ed.), *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_257`. The ports and oracles are clean-room implementations written from the operation's definition; no book prose or code is included. The book remains under its publisher's rights. The repository's license applies to the original package implementation.

## Files

- Workload: `workload.json`
- Primary oracle: [`benchmarks/negative_cycle_detection_oracle.py`](../../negative_cycle_detection_oracle.py)
- Independent verifier oracle: [`benchmarks/negative_cycle_detection_verifier_oracle.py`](../../negative_cycle_detection_verifier_oracle.py)
- Ports: C, C++, C3, Elisa, Nim, Odin, Rust, V, and Zig under their `n/` language directories.
