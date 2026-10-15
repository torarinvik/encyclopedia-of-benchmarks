# Ear Clipping Polygon Triangulation

This benchmark triangulates a simple polygon with deterministic ear clipping and returns original vertex indices.

## Contract

- Input is a flattened sequence of signed 64-bit integer coordinates `(x0,y0,...,xN-1,yN-1)` with 3 to 64 vertices.
- Each coordinate is in `[-10,000, 10,000]`. The polygon is implicitly closed from the last vertex to the first.
- Vertices must be distinct, the signed area must be nonzero, and the polygon must be simple. Self-intersections, touching nonadjacent edges, repeated vertices, and consecutive collinear triples are invalid.
- A valid polygon is triangulated while preserving its input winding. Each pass scans live vertices in original index order beginning at index 0, clips the first strict convex ear containing no other live vertex on or inside its triangle, and emits `(previous,current,next)`. The final three live vertices are emitted in cyclic polygon order.
- Return `N-2` and write each triangle as three original vertex indices encoded as little-endian unsigned 32-bit integers. Return `-1` for invalid input or polygon geometry, and `-2` when output storage is null or shorter than `12*(N-2)` bytes.
- Time complexity is `O(N^3)` and auxiliary storage is `O(N)`.

The pinned Python source implements ear clipping and assumes the supplied vertices form a valid simple polygon. The benchmark adds bounded integer input and explicit geometry validation so all ports have the same behavior. The catalog's C# `Triangulator` instead averages the coordinates of three radio stations and does not triangulate polygons, so it is a separate algorithm.

[`workload.json`](workload.json) covers both windings, convex and concave polygons, invalid sizes and coordinates, duplicate vertices, collinear triples, and self-intersections.

Build with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm ear_clipping_polygon_triangulation --language rust
```

## Upstream references

- [TheAlgorithms/Python ear clipping implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/ear_clipping_polygon_triangulation.py)
- [TheAlgorithms/C-Sharp station position calculator](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/Triangulator.cs)
