# Manhattan distance

Compute the n-dimensional L1 distance between two points.

## Contract

- The i64_array_float64 ABI encodes inputs as [dimension, point A coordinates..., point B coordinates...].
- The dimension must be from 1 through 16. Each coordinate is a signed integer from -1,000,000 through 1,000,000.
- The result is the sum of absolute coordinate differences as binary64.
- Invalid dimensions, array lengths, or coordinates return -1e300. Valid integer-coordinate inputs have exact integral results.

## Source semantics

This follows the pinned [TheAlgorithms Python manhattan_distance.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/manhattan_distance.py). The benchmark uses a bounded integer-coordinate subset of the source's numeric lists. The file's manhattan_distance_one_liner helper has the same behavior; this package maps the primary manhattan_distance function.

## Workload

The workload covers the two-dimensional and three-dimensional source examples, negative and equal coordinates, the coordinate bounds, and invalid shapes.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/manhattan_distance.c](../../../c/m/manhattan_distance.c) |
| C3 | [c3/m/manhattan_distance.c3](../../../c3/m/manhattan_distance.c3) |
| C++ | [cpp/m/manhattan_distance.cpp](../../../cpp/m/manhattan_distance.cpp) |
| Elisa | [elisa/m/manhattan_distance.elisa](../../../elisa/m/manhattan_distance.elisa) |
| Nim | [nim/m/manhattan_distance.nim](../../../nim/m/manhattan_distance.nim) |
| Odin | [odin/m/manhattan_distance.odin](../../../odin/m/manhattan_distance.odin) |
| Rust | [rust/m/manhattan_distance.rs](../../../rust/m/manhattan_distance.rs) |
| V | [v/m/manhattan_distance.v](../../../v/m/manhattan_distance.v) |
| Zig | [zig/m/manhattan_distance.zig](../../../zig/m/manhattan_distance.zig) |

The package uses the i64_array_float64 benchmark ABI.
