# Even tree edge removals

This benchmark counts the greatest number of edges that can be removed from an even-order tree so every remaining component has an even number of vertices.

## Contract

- Input uses `i64_array_scalar` and packs `[n, edge_count, u_0, v_0, ...]` in a signed 64-bit array.
- `n` must be even and in `2..=100`; `edge_count` must equal `n - 1`; each endpoint is a 1-based vertex in `1..=n`; the packed length must be exactly `2 + 2 * edge_count`.
- The edges must form a simple, connected, acyclic undirected tree. Malformed input, odd `n`, or a non-tree returns `INT64_MIN`.
- Root the tree at vertex 1. For each vertex, count its DFS subtree. A subtree with even size contributes one cut, including the root; the returned result is the source's `len(cuts) - 1`, so the root itself is never removed.
- The source assumes an even-order tree that can be decomposed into even-sized components. Under this contract every valid input satisfies that guarantee.
- The ports traverse a bounded adjacency matrix iteratively, then accumulate subtree sizes in reverse traversal order. The parity rule and root subtraction match the source while avoiding recursion in the ports.

## Upstream review

The pinned Python file constructs an undirected adjacency list from edges, marks visited vertices during DFS rooted at 1, appends every vertex whose returned subtree size is even, and prints `len(cuts) - 1`. Its function itself has no input or return value; the benchmark contract captures the file's complete example program behavior. The local packed ABI supplies the graph data that the source program currently hard-codes.

This tree-cut count is distinct from tree path enumeration and tree predicates such as sum-tree checks.

Reference: [Python `even_tree.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/even_tree.py).

## Implementations

The exported C ABI is `int64_t even_tree(const int64_t *values, size_t length)`. Implementations are provided in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig. `workload.json` covers the pinned ten-vertex example, simple paths and stars, and malformed graph encodings.

The source-backed oracle is implemented in [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py). Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm even_tree --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/e/even_tree/rust/build.json
```
