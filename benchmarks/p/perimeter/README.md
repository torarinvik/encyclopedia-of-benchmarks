# Perimeter of a regular polygon

This benchmark computes the perimeter of a regular polygon as side_count multiplied by side_length. It uses the shared behavior of the pinned Java regular-polygon method and the C++ n-polygon perimeter helper.

## Contract

Input is a signed-i64 array containing exactly [side_count, side_length]. The side count is 3 through 256, and the integer side length is 1 through 255. The function returns their product as a signed 64-bit integer. Malformed input returns -1.

These bounds keep the product at or below 65,280, so it is exactly representable by the Java source's float result and fits the C++ uint16_t self-test range as well as the shared i64 ABI. The benchmark covers the common regular-polygon formula; the C++ file also defines other shape formulas, while the Java file additionally defines irregular-polygon, rectangle, and circle formulas.

The [workload](workload.json) covers triangle, square, pentagon, and larger regular polygons, the maximum supported side count and length, and malformed inputs. The nine ports use the shared i64_array_scalar ABI and run in constant time and space.

## Pinned sources

- [C++ perimeter.cpp](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/perimeter.cpp), n_polygon_surface_perimeter.
- [C-Plus-Plus-1 perimeter.cpp](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/perimeter.cpp), same additional source snapshot.
- [Java Perimeter.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Perimeter.java), perimeterRegularPolygon.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/perimeter.c](../../../c/p/perimeter.c) |
| C3 | [c3/p/perimeter.c3](../../../c3/p/perimeter.c3) |
| C++ | [cpp/p/perimeter.cpp](../../../cpp/p/perimeter.cpp) |
| Elisa | [elisa/p/perimeter.elisa](../../../elisa/p/perimeter.elisa) |
| Nim | [nim/p/perimeter.nim](../../../nim/p/perimeter.nim) |
| Odin | [odin/p/perimeter.odin](../../../odin/p/perimeter.odin) |
| Rust | [rust/p/perimeter.rs](../../../rust/p/perimeter.rs) |
| V | [v/p/perimeter.v](../../../v/p/perimeter.v) |
| Zig | [zig/p/perimeter.zig](../../../zig/p/perimeter.zig) |
