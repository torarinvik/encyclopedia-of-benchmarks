# Haversine Rust source variant

This package preserves the distinct expression in the pinned Rust Haversine source. That file calculates 2 * sqrt(asin(a)) and multiplies by the Earth radius; this differs from the standard central-angle expression 2 * asin(sqrt(a)).

## Contract

- The i64_array_float64 ABI accepts exactly four integers: [latitude1, longitude1, latitude2, longitude2], with each coordinate stored in microdegrees (1,000,000 units per degree).
- Latitude values must be in [-90,000,000, 90,000,000]; longitude values must be in [-180,000,000, 180,000,000].
- The result is in meters, using the pinned source radius of 6,371,000 meters.
- The implementation calculates a = sin²(delta_latitude / 2) + cos(latitude1) cos(latitude2) sin²(delta_longitude / 2), then returns 2 * sqrt(asin(a)) * 6,371,000.
- The computed a is clamped to [0,1] to absorb binary64 endpoint rounding at coincident and antipodal coordinates. The source-specific expression is otherwise preserved.
- Invalid lengths and out-of-range coordinates return -1e300. Output tolerance is 1e-6 absolute and 1e-12 relative.

This benchmark is a source-faithful variant of the Rust file recorded under the mixed haversine candidate. It remains separate from the standard Haversine package because the source expression produces different results.

## Workload and runner

The workload uses the same bounded coordinate cases as the standard Haversine package, plus malformed lengths and out-of-range coordinates. The package uses the i64_array_float64 ABI family. The shared runner oracle is maintained by the coordinator.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/h/haversine_rust_variant.c](../../../c/h/haversine_rust_variant.c) |
| C3 | [c3/h/haversine_rust_variant.c3](../../../c3/h/haversine_rust_variant.c3) |
| C++ | [cpp/h/haversine_rust_variant.cpp](../../../cpp/h/haversine_rust_variant.cpp) |
| Elisa | [elisa/h/haversine_rust_variant.elisa](../../../elisa/h/haversine_rust_variant.elisa) |
| Nim | [nim/h/haversine_rust_variant.nim](../../../nim/h/haversine_rust_variant.nim) |
| Odin | [odin/h/haversine_rust_variant.odin](../../../odin/h/haversine_rust_variant.odin) |
| Rust | [rust/h/haversine_rust_variant.rs](../../../rust/h/haversine_rust_variant.rs) |
| V | [v/h/haversine_rust_variant.v](../../../v/h/haversine_rust_variant.v) |
| Zig | [zig/h/haversine_rust_variant.zig](../../../zig/h/haversine_rust_variant.zig) |

## Pinned source

- [Rust haversine.rs](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/navigation/haversine.rs)
