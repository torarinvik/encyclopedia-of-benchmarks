# Haversine distance

This package implements the standard spherical great-circle distance used by the pinned Java, JavaScript, Python, Nim, and Dart sources.

## Contract

- The i64_array_float64 ABI accepts exactly four integers: [latitude1, longitude1, latitude2, longitude2], with each coordinate stored in microdegrees (1,000,000 units per degree).
- Latitude values must be in [-90,000,000, 90,000,000]; longitude values must be in [-180,000,000, 180,000,000].
- The result is distance in kilometers using a spherical Earth radius of 6,371 km.
- The implementation computes a = sin²(delta_latitude / 2) + cos(latitude1) cos(latitude2) sin²(delta_longitude / 2), then returns 6,371 * 2 * atan2(sqrt(a), sqrt(1-a)).
- The computed a is clamped to [0,1] to absorb binary64 endpoint rounding at coincident and antipodal coordinates.
- Invalid lengths and out-of-range coordinates return -1e300. Output tolerance is 1e-9 absolute and 1e-12 relative.

The Java, JavaScript, Python, and Dart sources take degree coordinates and use Earth radii expressed in kilometers or meters. The Nim source takes radians and returns the unit-sphere central angle. The shared contract normalizes their input and output units while preserving the same standard Haversine calculation.

## Workload and runner

The workload covers identical points, one-degree offsets, a quarter-equator arc, a short antimeridian crossing, high-latitude points, pinned city examples, antipodal endpoints, malformed lengths, and out-of-range coordinates. The package uses the i64_array_float64 ABI family. The shared runner oracle is maintained by the coordinator.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/h/haversine_distance.c](../../../c/h/haversine_distance.c) |
| C3 | [c3/h/haversine_distance.c3](../../../c3/h/haversine_distance.c3) |
| C++ | [cpp/h/haversine_distance.cpp](../../../cpp/h/haversine_distance.cpp) |
| Elisa | [elisa/h/haversine_distance.elisa](../../../elisa/h/haversine_distance.elisa) |
| Nim | [nim/h/haversine_distance.nim](../../../nim/h/haversine_distance.nim) |
| Odin | [odin/h/haversine_distance.odin](../../../odin/h/haversine_distance.odin) |
| Rust | [rust/h/haversine_distance.rs](../../../rust/h/haversine_distance.rs) |
| V | [v/h/haversine_distance.v](../../../v/h/haversine_distance.v) |
| Zig | [zig/h/haversine_distance.zig](../../../zig/h/haversine_distance.zig) |

## Pinned sources

- [Java Haversine.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/geometry/Haversine.java)
- [JavaScript Haversine.js](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Navigation/Haversine.js)
- [Python haversine_distance.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/geodesy/haversine_distance.py)
- [Nim haversine_distance.nim](https://github.com/TheAlgorithms/Nim/blob/63eec16614b46c91078653e8d3c049fe99ad36b3/maths/haversine_distance.nim)
- [Dart haversine_formula.dart](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/other/haversine_formula.dart)
