# Bentley–Ottmann segment intersections

This package returns distinct proper intersections among nonvertical line segments. Each segment is supplied as `[x1, y1, x2, y2]`; endpoints are normalized left-to-right. Input is `[segment_count, x1, y1, x2, y2, ...]`, with at most 24 segments and integer coordinates in `[-1000, 1000]`.

The supported geometry has strict preconditions: no shared endpoints, no collinear overlaps, every intersection is a proper crossing at an integer lattice point, and all endpoint/intersection x-coordinates are distinct. These conditions avoid event ties and degeneracies. Ports enforce count, coordinate, and nonvertical-segment bounds but do not perform quadratic prevalidation of all geometric preconditions.

Output is `[intersection_count, x0, y0, x1, y1, ...]` as little-endian signed 64-bit values, with points sorted lexicographically by x then y. Malformed inputs return `-1`; a null or undersized output buffer returns `-2`; success returns the output byte length.

## Source and normalization

Pinned source: [TheAlgorithms/Java BentleyOttmann.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/geometry/BentleyOttmann.java) at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

The Java implementation uses `double` coordinates with an epsilon, mutable sweep-position ordering inside a `TreeSet`, and exact `Point2D.Double` set equality. Its event tie ordering and collinear/vertical handling are not deterministic enough for a portable cross-language output contract. This package preserves the sweep-line neighbor scheduling on the restricted domain and uses exact integer rational comparisons. The set output is normalized to lexicographic order. It is source-inspired and intentionally excludes the pinned implementation's degenerate geometry behavior.
