# Area of a polygon

This benchmark computes the area of one or more ordered polygon boundaries with the shoelace formula used by the pinned Rust source. Each vertex has integer coordinates. The exact result is represented as twice the area, so half-unit results remain exact and no floating-point rounding or processor-specific instructions affect the comparison.

## Contract

- Input is `[polygon_count, vertex_count_0, x_0, y_0, ...]`, followed by each polygon's vertex count and ordered coordinate pairs.
- There are 0 through 32 polygons. Every polygon has 3 through 128 vertices, and the complete input has at most 512 vertices.
- Coordinates are in `[-1,000,000, 1,000,000]`. Vertex order may be clockwise or counterclockwise and may describe concave or self-intersecting boundaries; self-intersections use the absolute algebraic shoelace result. A repeated closing vertex is allowed.
- For polygon `i`, let `cross = sum(x_j*y_(j+1) - x_(j+1)*y_j)` with indices wrapping around. Its returned doubled area is `abs(cross)`. The scalar result is the weighted sum `(i+1) * (doubled_area + 1,000,000,007)`.
- An empty polygon list returns zero. Malformed counts, coordinates, lengths, or trailing values return `-1`.

The exact integer-coordinate contract preserves the source algorithm while making its result portable through the signed 64-bit array/scalar ABI. It avoids a floating-point tolerance and bounds every intermediate value.

## Workload and verification

[`workload.json`](workload.json) covers empty input, both vertex orientations, convex and concave polygons, multiple polygons, large coordinates, and malformed inputs. [`verify_area_of_polygon.py`](../../verify_area_of_polygon.py) compares all nine implementations with an independent integer shoelace oracle, including every ordered triangle drawn from a small coordinate grid, deterministic randomized polygons, malformed arrays, and the recorded workload.

## Reviewed TheAlgorithms source

- [Rust `area_of_polygon.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/area_of_polygon.rs) — wraps from the last point to the first and returns the absolute shoelace sum divided by two. The benchmark keeps that calculation exact for bounded integer coordinates and reports the doubled area.

## Implementations

The nine portable implementations use the shared `i64_array_scalar` ABI. Each source is under the `a` folder for its language.
