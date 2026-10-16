# Car pool

Check whether every route segment stays within the available passenger capacity using a difference timeline.

## Contract

The `i64_array_scalar` input is `[capacity, trip_count, passengers, origin, destination, ...]`, with up to 64 trips. Capacity is 0 through 1000, passengers are 1 through 1000, and each route satisfies `0 <= origin < destination <= 1000`. A trip occupies the half-open segment `[origin, destination)`. The result is `1` when capacity is respected and `0` when it is exceeded. Malformed input returns `-1`.

The pinned Dart source uses a 1001-entry difference array but starts its cumulative check at stop 1. That skips the segment from stop 0 to stop 1, so overlapping trips on that segment can incorrectly pass. The benchmark checks every occupied segment, including that first one, while retaining the source's event-array method.

[`workload.json`](workload.json) covers capacity boundaries, shared dropoff and pickup stops, routes from stop zero, the maximum stop, and malformed traces. All nine ports passed 925 oracle arrays each and recorded all 11 workload cases. The verifier exhausts small pairs of routes and adds deterministic random traces through the 64-trip bound.

```sh
python3 benchmarks/verify_i64_array_scalar.py --algorithm car_pool --jobs 3 --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm car_pool --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/c/car_pool/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/c/car_pool.c`](../../../c/c/car_pool.c) |
| C3 | [`c3/c/car_pool.c3`](../../../c3/c/car_pool.c3) |
| C++ | [`cpp/c/car_pool.cpp`](../../../cpp/c/car_pool.cpp) |
| Elisa | [`elisa/c/car_pool.elisa`](../../../elisa/c/car_pool.elisa) |
| Nim | [`nim/c/car_pool.nim`](../../../nim/c/car_pool.nim) |
| Odin | [`odin/c/car_pool.odin`](../../../odin/c/car_pool.odin) |
| Rust | [`rust/c/car_pool.rs`](../../../rust/c/car_pool.rs) |
| V | [`v/c/car_pool.v`](../../../v/c/car_pool.v) |
| Zig | [`zig/c/car_pool.zig`](../../../zig/c/car_pool.zig) |

## TheAlgorithms reference

- [Dart `car_pool.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/array/car_pool.dart)
