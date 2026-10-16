# Greedy graph coloring

This benchmark ports the pinned Go maximum-degree-first greedy coloring. The Go source builds its degree list from a map and compares only degree, so tied order can vary between runs; the portable contract resolves ties by ascending vertex ID.

## Contract

- Input is `[vertex_count, neighbor_mask_0, ..., neighbor_mask_(n-1)]`, with `0..14` vertices numbered `0..n-1`.
- The graph must be simple and undirected. Self-loops, asymmetric masks, and out-of-range bits are invalid and return `-1`.
- Vertices are visited by descending degree, then ascending ID. Each gets the smallest positive color unused by an already-colored neighbor.
- The signed-64-bit result stores the color count in its low four bits, followed by one four-bit color ID per vertex in original ID order. The 14-vertex bound keeps the result below bit 60. The empty graph returns `0`.

The pinned source returns both the vertex-to-color map and the number of colors. The packed scalar preserves both; Go map iteration and sort tie behavior are normalized as described above.

## Pinned source

- [TheAlgorithms/Go `greedy.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/coloring/greedy.go)
- [TheAlgorithms/Go `graph.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/coloring/graph.go)
