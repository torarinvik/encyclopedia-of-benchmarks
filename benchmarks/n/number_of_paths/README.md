# Number of paths

Count simple directed paths between two vertices in a graph represented by an
adjacency matrix. The benchmark follows the pinned C++ DFS routine's path and
edge semantics.

## Contract

- Input uses the `i64_array_scalar` ABI with the packed layout
  `[n, source, destination, A[0][0], A[0][1], ..., A[n-1][n-1]]`. Matrix cells
  are row-major.
- `n` is in `1..=10`. Vertex indices are zero-based unsigned 32-bit values.
  Matrix entries are `0` or `1`; an edge exists only when its cell equals `1`.
- The function returns the number of directed paths from `source` to
  `destination` that do not visit a vertex more than once. When the endpoints
  are equal, it returns `1` immediately, including for a graph with cycles.
  Cycles are otherwise allowed in the graph, but the DFS backtracks its
  `visited` marks, so a path cannot repeat a vertex.
- Out-of-range source or destination indices return `0`, matching the pinned
  function. Malformed packed inputs (wrong length, unsupported `n`, negative
  indices, or non-binary matrix cells) return `-1` as the ABI sentinel.
- The `n <= 10` bound limits exhaustive DFS work. Even a complete directed
  graph has at most 109,601 simple paths between distinct vertices at this
  size, safely within the source's `uint32_t` count and the ABI's signed
  64-bit result.

## Pinned source

The pinned [C++ `number_of_paths.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/number_of_paths.cpp)
uses recursive DFS over the adjacency matrix. It returns `1` when the current
vertex is already the destination, follows only cells equal to `1`, and marks
then unmarks vertices during recursion. This counts simple paths, including
the zero-length path when source equals destination.

The similarly named Python `count_paths` candidate counts paths through a
four-neighbor grid with blocked cells; that is a different input model and is
not part of this benchmark.

## Workload and build

[`workload.json`](workload.json) covers the pinned examples, source-equals-
destination behavior, invalid endpoints, a cyclic graph, and a complete graph
at the supported size limit. The maximum packed input is 103 signed 64-bit
values, within the existing array scalar runner limit.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm number_of_paths --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/n/number_of_paths/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/n/number_of_paths.c`](../../../c/n/number_of_paths.c) |
| C3 | [`c3/n/number_of_paths.c3`](../../../c3/n/number_of_paths.c3) |
| C++ | [`cpp/n/number_of_paths.cpp`](../../../cpp/n/number_of_paths.cpp) |
| Elisa | [`elisa/n/number_of_paths.elisa`](../../../elisa/n/number_of_paths.elisa) |
| Nim | [`nim/n/number_of_paths.nim`](../../../nim/n/number_of_paths.nim) |
| Odin | [`odin/n/number_of_paths.odin`](../../../odin/n/number_of_paths.odin) |
| Rust | [`rust/n/number_of_paths.rs`](../../../rust/n/number_of_paths.rs) |
| V | [`v/n/number_of_paths.v`](../../../v/n/number_of_paths.v) |
| Zig | [`zig/n/number_of_paths.zig`](../../../zig/n/number_of_paths.zig) |
