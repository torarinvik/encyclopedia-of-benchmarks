# Distance between two points

Compute the straight-line Euclidean distance between two points in a two-dimensional plane, using the formula `sqrt((x2 - x1)^2 + (y2 - y1)^2)` from the pinned Java implementation.

## Contract

- Input is exactly four signed 64-bit integers in the order `[x1, y1, x2, y2]`.
- Each coordinate is in `[-1,000,000, 1,000,000]`. Empty, wrong-length, or out-of-range input returns `-1e300`.
- A valid input returns the binary64 square root of the sum of the squared coordinate differences, with absolute and relative tolerances of `1e-12`.
- The coordinate bound keeps differences and squared sums exact in binary64 and safely bounded in signed 64-bit arithmetic. The maximum valid distance is `sqrt(8,000,000,000,000)`.
- Runtime and auxiliary space are both `O(1)`.

## Relationship to other geometry benchmarks

This is a fixed two-dimensional point-distance calculation from four scalar coordinates. The `euclidean_distance` candidate accepts two vectors of arbitrary dimension, while `points_are_collinear_3d` tests a three-dimensional predicate and `vector_cross_product` calculates a three-dimensional cross product. `distance_between_bus_stops` sums distances along a circular route. They use related geometry or the word “distance” but benchmark different input shapes and operations.

The source Java method accepts four doubles without validation. The shared ABI uses integer arrays, so this benchmark defines a bounded integral-coordinate subset and a finite invalid-input sentinel.

## Workload and recording

The workload includes coincident, horizontal, vertical, diagonal, negative-coordinate, irrational, maximum-bound, and invalid-shape/domain cases. All ports use the existing `i64_array_float64` ABI.

## Verification

Run the independent bounded corpus through each available language implementation with:

```sh
python3 benchmarks/verify_distance_between_two_points.py
```

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm distance_between_two_points --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/d/distance_between_two_points/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [c/d/distance_between_two_points.c](../../../c/d/distance_between_two_points.c) |
| C3 | [c3/d/distance_between_two_points.c3](../../../c3/d/distance_between_two_points.c3) |
| C++ | [cpp/d/distance_between_two_points.cpp](../../../cpp/d/distance_between_two_points.cpp) |
| Elisa | [elisa/d/distance_between_two_points.elisa](../../../elisa/d/distance_between_two_points.elisa) |
| Nim | [nim/d/distance_between_two_points.nim](../../../nim/d/distance_between_two_points.nim) |
| Odin | [odin/d/distance_between_two_points.odin](../../../odin/d/distance_between_two_points.odin) |
| Rust | [rust/d/distance_between_two_points.rs](../../../rust/d/distance_between_two_points.rs) |
| V | [v/d/distance_between_two_points.v](../../../v/d/distance_between_two_points.v) |
| Zig | [zig/d/distance_between_two_points.zig](../../../zig/d/distance_between_two_points.zig) |

## Pinned source

- [Java `DistanceBetweenTwoPoints.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/DistanceBetweenTwoPoints.java)
- [Generic `euclidean_distance` candidate in Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/euclidean_distance.py)
