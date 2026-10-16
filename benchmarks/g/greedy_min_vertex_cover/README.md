# Greedy minimum vertex cover

This benchmark preserves the pinned Python implementation's deterministic maximum-current-degree greedy heuristic for undirected graphs. It is a heuristic and does not guarantee a minimum-cardinality cover.

## Contract

- Input is `[vertex_count, neighbor_mask_0, ..., neighbor_mask_(n-1)]` as signed 64-bit integers. There are 1–16 vertices with IDs `0..vertex_count-1`; each mask uses bit `j` to indicate an edge to vertex `j`.
- The graph must be simple and undirected: masks are symmetric, have no self-loop bits, and contain no out-of-range bits. Duplicate edges cannot be represented in this encoding. Invalid input returns `-1`.
- Repeatedly choose a vertex of maximum current degree, breaking ties by the smallest vertex ID; add it to the cover and remove its incident edges. Stop when no edges remain.
- Output is the chosen vertex set as a nonnegative signed-64-bit bitmask, where bit `i` is set when vertex `i` is selected. An edgeless graph returns `0`.

The bounded integer-ID graph contract preserves the source's degree updates and tie behavior while avoiding Python object labels and set iteration details.

[`workload.json`](workload.json) covers an edgeless graph, a star, a path, a triangle tie, disjoint components, and malformed asymmetric, self-loop, and out-of-range inputs. The scalar result is suitable for the `i64_array_scalar_call` comparison model. Verify the nine ports with:

```sh
python3 benchmarks/verify_i64_array_scalar.py --algorithms greedy_min_vertex_cover
```

## Implementations

All nine portable implementations use the shared `i64_array_scalar` ABI and reside in each language's `g` folder.

## Pinned source

- [TheAlgorithms/Python `greedy_min_vertex_cover.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/greedy_min_vertex_cover.py)
