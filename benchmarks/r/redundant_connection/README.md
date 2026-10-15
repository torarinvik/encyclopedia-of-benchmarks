# Redundant connection

This benchmark finds the input edge that first joins two vertices already connected by earlier edges. Removing it leaves a tree.

## Contract

- The input is a flat sequence of endpoint pairs: `[u1, v1, u2, v2, ...]`.
- It contains 3 to 1,000 edges over vertices `1..n`, where `n` is the edge count. The input must describe a connected graph with exactly one cycle; self-loops and endpoints outside `1..n` are invalid.
- Invalid inputs return `-1`. If the output buffer has fewer than eight bytes, the function returns `-2` without writing.
- On success, the function returns `2` and writes the redundant edge's two endpoints in input order as little-endian signed 32-bit integers.

## Upstream review

The pinned C implementation uses disjoint-set union, scans edges in input order, and records an edge when its endpoints already have the same root. The benchmark makes the graph constraints explicit and uses caller-owned output storage. Source: [TheAlgorithms/C, 684.c](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/684.c).

## Implementations

The nine portable implementations use disjoint-set union with path compression. They return the edge that closes the cycle in input order and leave the input untouched.

## Workload and verification

`workload.json` covers the published triangle, a cycle closed before later tree edges, a long path closed by its final edge, invalid endpoint and self-loop cases, a graph with multiple cycles, malformed input, and the maximum supported size. `benchmarks/verify_redundant_connection.py` checks exhaustive small graphs, deterministic random trees with one added edge, contract boundaries, and every workload record in all nine languages.

Build and record with the `i64_array_bytes_output` ABI family and `benchmarks/run_i64_array_bytes_output.py`.
