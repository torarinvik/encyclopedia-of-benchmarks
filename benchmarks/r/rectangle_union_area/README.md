# Rectangle Union Area

Compute the area covered by two axis-aligned rectangles. The algorithm adds both rectangle areas and subtracts their intersection area, matching the pinned C LeetCode 223 implementation.

## Contract

- Pass eight signed coordinates in `[ax1, ay1, ax2, ay2, bx1, by1, bx2, by2]` order.
- Coordinates must be in `[-1,000,000,000, 1,000,000,000]`, with each lower bound strictly below its upper bound. Invalid lengths, coordinates, or rectangles return `-1`.
- The input is read only. The result is the union area as a signed 64-bit integer.
- Each implementation performs a fixed number of integer operations: O(1) time and O(1) auxiliary space.

## Workload and verification

[`workload.json`](workload.json) covers identical, contained, overlapping, touching, disjoint, negative-coordinate, and large-coordinate rectangles. [`benchmarks/verify_rectangle_union_area.py`](../../verify_rectangle_union_area.py) checks all nine implementations against an independent clipping oracle, including exhaustive small-grid rectangles, deterministic random cases, coordinate boundaries, and malformed inputs.

## Upstream source

- [TheAlgorithms/C LeetCode 223](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/223.c)
