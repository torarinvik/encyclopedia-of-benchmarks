# Initial bearing

## Contract

Return the initial forward bearing from one geographic point to another, measured clockwise from true north. Input is four signed 64-bit integers `[latitude1, longitude1, latitude2, longitude2]` in microdegrees. Latitude must be in `[-90,000,000, 90,000,000]`, longitude in `[-180,000,000, 180,000,000]`, and the two coordinate pairs must differ. Invalid lengths, out-of-range coordinates, or identical points return `-1`.

The result is the bearing rounded to the nearest microdegree and represented as an integer in `[0, 360,000,000)`. The spherical initial-bearing formula is `atan2(sin(Δλ) cos(φ₂), cos(φ₁) sin(φ₂) − sin(φ₁) cos(φ₂) cos(Δλ))`, converted from radians to degrees and normalized clockwise from north. The exported ABI is `int64_t bearing(const int64_t *values, size_t length)`.

## Source review and distinctness

The pinned Rust source takes four floating-point coordinates and applies the spherical forward-bearing formula. The pinned Python source documents the same result and rejects identical points; Rust does not reject that input, so this benchmark adopts the explicit Python behavior. Neither source validates geographic ranges, which this bounded contract makes explicit for portable inputs. Existing geometry benchmarks cover areas and route distances; none computes an initial bearing between latitude/longitude points, so `bearing` is a distinct benchmark.

## Workload and recording

[`workload.json`](workload.json) covers cardinal and diagonal directions, source examples, antimeridian crossings, invalid coordinates, identical points, and malformed input lengths. Runtime verification remains pending. Build and record with the `i64_array_scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm bearing --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/bearing/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bearing.c`](../../../c/b/bearing.c) |
| C3 | [`c3/b/bearing.c3`](../../../c3/b/bearing.c3) |
| C++ | [`cpp/b/bearing.cpp`](../../../cpp/b/bearing.cpp) |
| Elisa | [`elisa/b/bearing.elisa`](../../../elisa/b/bearing.elisa) |
| Nim | [`nim/b/bearing.nim`](../../../nim/b/bearing.nim) |
| Odin | [`odin/b/bearing.odin`](../../../odin/b/bearing.odin) |
| Rust | [`rust/b/bearing.rs`](../../../rust/b/bearing.rs) |
| V | [`v/b/bearing.v`](../../../v/b/bearing.v) |
| Zig | [`zig/b/bearing.zig`](../../../zig/b/bearing.zig) |

## TheAlgorithms references

- Rust [`bearing.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/navigation/bearing.rs)
- Python [`bearing.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/bearing.py)
