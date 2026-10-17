# Iterative Deepening Depth-First Search

This benchmark follows `iddfs()` from the pinned [TheAlgorithms/R source](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/graph_algorithms/iddfs.r). It preserves the source's iterative depth limits, recursive depth-limited DFS neighbor order, path-local cycle avoidance, and first shallowest route. The normalizer creates every vertex from 1 through the maximum named or neighbor ID, gives missing vertices empty adjacency, and filters neighbors below 1. Verbose progress and normalization warnings are omitted; the returned search result is the benchmarked behavior.

## Contract

Input is the signed-i64 array `[start, target, max_depth, entry_count, vertex_id, degree, neighbors..., ...]`. It contains at most 16 distinct named vertices, at most 64 total neighbor entries, IDs in `1..16`, neighbor values in `-16..16`, and a depth limit in `0..8`. Neighbors below 1 are discarded as in the R normalizer. Named vertices may be omitted: the normalizer inserts empty adjacency for gaps and for positive neighbor IDs that have no named entry. Entries are encoded in their original order, and each neighbor list retains its order and duplicates. The packed length must exactly match the entry/degree framing. The valid input maximum is 100 i64 values; one additional parseable value is accepted for a bounded invalid-framing case.

For a nonempty normalized graph, start and target must be in `1..max_vertex`. An empty graph returns not-found before membership checks, following the source. Malformed input returns `-1`. The output is a little-endian signed-i64 record `[found, depth, path_length, path_vertices...]`: found is 1 or 0, and a not-found result uses depth `-1` for the source's `NA_integer_` and path length 0. A valid result returns its byte count. Null or undersized output returns `-2`; input errors take precedence, and error paths write nothing. The maximum output record is 96 bytes.

[`workload.json`](workload.json) contains 41 cases for the pinned source example, shallowest-path and neighbor-order behavior, depth limits, start-equals-target, cycles, missing vertices, filtered neighbors, empty and unreachable graphs, maximum sizes, invalid framing/ranges, and output capacity/error precedence. The independent oracle is [`iddfs_oracle.py`](../../iddfs_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`iddfs.c`](../../../c/i/iddfs.c) |
| C3 | [`iddfs.c3`](../../../c3/i/iddfs.c3) |
| C++ | [`iddfs.cpp`](../../../cpp/i/iddfs.cpp) |
| Elisa | [`iddfs.elisa`](../../../elisa/i/iddfs.elisa) |
| Nim | [`iddfs.nim`](../../../nim/i/iddfs.nim) |
| Odin | [`iddfs.odin`](../../../odin/i/iddfs.odin) |
| Rust | [`iddfs.rs`](../../../rust/i/iddfs.rs) |
| V | [`iddfs.v`](../../../v/i/iddfs.v) |
| Zig | [`iddfs.zig`](../../../zig/i/iddfs.zig) |

Build, record, and verify a port with the `i64_array_bytes_output` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm iddfs --language c
python3 benchmarks/run_i64_array_bytes_output.py --algorithm iddfs
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm iddfs
```

## Pinned source

[TheAlgorithms/R `iddfs.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/graph_algorithms/iddfs.r), commit `f65344fabeea0ae33c1ca321af709447c1a8a4c2`.
