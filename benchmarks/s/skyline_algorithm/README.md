# Divide-and-conquer skyline

This benchmark covers the pinned Java `SkylineAlgorithm.produceSubSkyLines` operation. It returns the lower-left Pareto frontier for points already ordered by x, preserving input order.

## Contract

The ABI is `i64_array_bytes_output`. Input is `[point_count, x0, y0, ..., x(point_count-1), y(point_count-1)]`, with 1 through 64 points. Coordinates must fit signed 32-bit integers; every y coordinate must be at least 1, and x coordinates must be strictly increasing. The source does not sort the input. Nonempty input avoids the source's unhandled empty-list recursion, and positive y values make its early exit when the running minimum reaches 1 correct.

The source's strict dominance rule removes a point when another point has no larger x and y and is strictly smaller in at least one coordinate. It recursively splits the list at `size / 2`, merges the left and right frontiers, retains input order, and removes right-side points whose y is greater than or equal to the minimum y in the left frontier.

Serialize the result as one point-count byte followed by each point in source order as signed little-endian i32 x and y coordinates. The result is bounded by 513 bytes. Malformed framing, unsupported point counts, out-of-range coordinates, nonpositive y, or non-increasing x returns `-1` before output checks. A null output or insufficient capacity returns `-2` without writes.

## Pinned source

- `SkylineAlgorithm.produceSubSkyLines`, `produceFinalSkyLine`, and `Point.dominates`: [TheAlgorithms/Java at `e43ec3897e48f23843972d02cd05a5bb1b6864a2`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/divideandconquer/SkylineAlgorithm.java)

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`skyline_algorithm_oracle.py`](../../skyline_algorithm_oracle.py)
