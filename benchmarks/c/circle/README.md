# Circle calculations

Compute the perimeter or area of a circle using the pinned JavaScript class.

## Contract

- The `float64_pair` ABI receives `[radius, operation]`. Radius is a finite binary64 value in `[-1,000,000, 1,000,000]`.
- Operation `0` returns perimeter, using the source order `radius * 2 * PI`. Operation `1` returns area, using `radius² * PI`. The workload lists perimeter cases before area cases.
- Negative radii are valid: perimeter remains signed and area is nonnegative, matching the class formulas. Invalid radius or operation returns `-1e300`.
- Results are compared with absolute tolerance `1e-12` and input-scaled relative tolerance `1e-9`, allowing a few binary64 ULPs in the large area results.

## Source and workload

This package follows the pinned [TheAlgorithms/JavaScript `Circle.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Geometry/Circle.js). The class stores a radius and exposes separate perimeter and area methods; the operation selector lets the two methods share the benchmark's two-input, one-result ABI.

[`workload.json`](workload.json) covers both operations, zero and negative radii, the domain boundaries, and invalid selectors/radii. The independent source-shaped oracle is [`circle_oracle.py`](../../circle_oracle.py).

Build and record with the shared runner:

```sh
python3 benchmarks/build_abi.py --family float64_pair --algorithm circle --language rust
python3 benchmarks/run_float64_pair.py --build-manifest build/float64_pair/c/circle/rust/build.json
```

Verify all nine ports against the independent oracle and workload with:

```sh
python3 benchmarks/verify_circle.py
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/circle.c`](../../../c/c/circle.c) |
| C3 | [`c3/c/circle.c3`](../../../c3/c/circle.c3) |
| C++ | [`cpp/c/circle.cpp`](../../../cpp/c/circle.cpp) |
| Elisa | [`elisa/c/circle.elisa`](../../../elisa/c/circle.elisa) |
| Nim | [`nim/c/circle.nim`](../../../nim/c/circle.nim) |
| Odin | [`odin/c/circle.odin`](../../../odin/c/circle.odin) |
| Rust | [`rust/c/circle.rs`](../../../rust/c/circle.rs) |
| V | [`v/c/circle.v`](../../../v/c/circle.v) |
| Zig | [`zig/c/circle.zig`](../../../zig/c/circle.zig) |
