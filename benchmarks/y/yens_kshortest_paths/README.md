# Yen's k shortest loopless paths

This benchmark implements Yen's algorithm for up to `k` shortest loopless paths in a directed graph. It is distinct from shortest distance benchmarks because it enumerates alternatives and orders complete paths by total cost, then lexicographically by their vertex sequences.

## Contract

- Input is `[n, k, src, dst, adjacency_row_major...]` in the signed 64-bit array ABI. `n` is 1–8, `k` is 1–8, and both vertex indices are in `0..n-1`. Exactly `4+n*n` values are required.
- The row-major adjacency matrix uses `-1` for no edge and weights 0–1000 for present edges. The graph is directed. Zero-weight edges are valid.
- Output is a little-endian signed 64-bit stream `[path_count, path_length_0, vertices..., cost_0, ...]`, in ascending `(cost, vertex sequence)` order. A source equal to destination returns the one-vertex zero-cost path. An unreachable destination returns an empty stream containing only `path_count=0`.
- Malformed input returns `-1`; insufficient output capacity returns `-2`. The matrix is not modified.
- Each spur search removes the next edge of every already accepted path sharing the root prefix and blocks earlier root vertices. Candidate paths are deduplicated by their vertex sequence.

[`workload.json`](workload.json) covers ranked alternatives, equal-cost ordering, zero weights, unreachable destinations, source equal to destination, and malformed input. The bounded graph domain keeps exhaustive differential checking tractable while preserving Yen's path selection behavior.

## Source

- [TheAlgorithms/Java `YensKShortestPaths.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/YensKShortestPaths.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

The pinned Java priority queue compares Dijkstra nodes by distance only, so its parent choices are not guaranteed to be lexicographically smallest for equal-cost paths. This benchmark specifies lexicographic tie-breaking so equal-cost outcomes are deterministic across languages; `zero-weight-dijkstra-lex-tie-regression` captures a graph where choosing a stable path tie matters.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/y/yens_kshortest_paths.c`](../../../c/y/yens_kshortest_paths.c) |
| C3 | [`c3/y/yens_kshortest_paths.c3`](../../../c3/y/yens_kshortest_paths.c3) |
| C++ | [`cpp/y/yens_kshortest_paths.cpp`](../../../cpp/y/yens_kshortest_paths.cpp) |
| Elisa | [`elisa/y/yens_kshortest_paths.elisa`](../../../elisa/y/yens_kshortest_paths.elisa) |
| Nim | [`nim/y/yens_kshortest_paths.nim`](../../../nim/y/yens_kshortest_paths.nim) |
| Odin | [`odin/y/yens_kshortest_paths.odin`](../../../odin/y/yens_kshortest_paths.odin) |
| Rust | [`rust/y/yens_kshortest_paths.rs`](../../../rust/y/yens_kshortest_paths.rs) |
| V | [`v/y/yens_kshortest_paths.v`](../../../v/y/yens_kshortest_paths.v) |
| Zig | [`zig/y/yens_kshortest_paths.zig`](../../../zig/y/yens_kshortest_paths.zig) |

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm yens_kshortest_paths --language c
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/y/yens_kshortest_paths/c/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm yens_kshortest_paths
```
