# Jarvis scan

This benchmark ports the pinned Rust Jarvis march (gift-wrapping) routine. It reports the convex hull in counter-clockwise order, starting at the leftmost point and breaking ties by the lowest y-coordinate. The pinned Python and C++ variants implement the same wrapping scan and are cataloged as aliases on their shared input domain.

## Contract

- Input is `[point_count, x_0, y_0, ...]` using signed 64-bit integers. There are at most 64 points, with each coordinate in `[-10000, 10000]`.
- For inputs with at least three points, coordinates must be distinct and no three points may be collinear. The source uses floating-point points and tolerance-based segment cleanup; this exact integer domain removes that source-specific ambiguity while retaining the Jarvis scan.
- Zero, one, and two points produce an empty hull, matching the source. Invalid shape, coordinate bounds, duplicate points, or collinear triples return `-1`.
- Output is the ordered hull as `[x_0, y_0, x_1, y_1, ...]`, encoded as little-endian signed 64-bit integers. The return value is the number of output bytes; an empty hull returns `0`, and insufficient output capacity returns `-2`.
- The fixed-size ports use integer cross products over the bounded coordinate range, so orientation does not depend on architecture-specific floating-point behavior.

[`workload.json`](workload.json) covers empty and small inputs, triangle and rectangle hulls, a 64-point general-position set, malformed geometry, and output-capacity failure.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm jarvis_scan --language c
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/j/jarvis_scan/c/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithms jarvis_scan
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/j/jarvis_scan.c`](../../../c/j/jarvis_scan.c) |
| C3 | [`c3/j/jarvis_scan.c3`](../../../c3/j/jarvis_scan.c3) |
| C++ | [`cpp/j/jarvis_scan.cpp`](../../../cpp/j/jarvis_scan.cpp) |
| Elisa | [`elisa/j/jarvis_scan.elisa`](../../../elisa/j/jarvis_scan.elisa) |
| Nim | [`nim/j/jarvis_scan.nim`](../../../nim/j/jarvis_scan.nim) |
| Odin | [`odin/j/jarvis_scan.odin`](../../../odin/j/jarvis_scan.odin) |
| Rust | [`rust/j/jarvis_scan.rs`](../../../rust/j/jarvis_scan.rs) |
| V | [`v/j/jarvis_scan.v`](../../../v/j/jarvis_scan.v) |
| Zig | [`zig/j/jarvis_scan.zig`](../../../zig/j/jarvis_scan.zig) |

## Source

- [Pinned Rust `jarvis_scan.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/geometry/jarvis_scan.rs)
- [Pinned Python `jarvis_march.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/geometry/jarvis_march.py)
- [Pinned C++ `jarvis_algorithm.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/geometry/jarvis_algorithm.cpp) ([identical copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/geometry/jarvis_algorithm.cpp)); its source starts at the first input point with minimum x, so its alias domain requires a unique minimum x and at least three valid points.
