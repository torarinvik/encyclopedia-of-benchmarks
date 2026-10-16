# Cone

This package ports the pinned JavaScript `Cone` methods for volume and total surface area. It selects one scalar result per call through the shared `i64_array_float64` ABI.

## Contract

- Input is exactly `[operation, radius, height]`, with operation `0` for volume or `1` for surface area.
- Radius and height are integer dimensions in `[0, 1000]`. This bounded subset keeps all intermediates finite and within a portable binary64 range.
- The base area is `radius² × π`. Volume preserves the source expression `(baseArea × height × 1) / 3`; surface area is `baseArea + π × radius × sqrt(radius² + height²)`.
- Malformed lengths, unsupported selectors, and dimensions outside the contract return `-1e300`. Valid values use absolute tolerance `1e-9` and relative tolerance `1e-12`.

## Workload and verification

[`workload.json`](workload.json) covers both methods, zero dimensions, a 3-4-5 slant, a 5-12-13 slant, the maximum bounded dimensions, and malformed inputs. Run the independent bounded corpus through each available language implementation with:

```sh
python3 benchmarks/verify_cone.py
```

## Pinned source

- JavaScript [`Cone.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Geometry/Cone.js)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/cone.c`](../../../c/c/cone.c) |
| C3 | [`c3/c/cone.c3`](../../../c3/c/cone.c3) |
| C++ | [`cpp/c/cone.cpp`](../../../cpp/c/cone.cpp) |
| Elisa | [`elisa/c/cone.elisa`](../../../elisa/c/cone.elisa) |
| Nim | [`nim/c/cone.nim`](../../../nim/c/cone.nim) |
| Odin | [`odin/c/cone.odin`](../../../odin/c/cone.odin) |
| Rust | [`rust/c/cone.rs`](../../../rust/c/cone.rs) |
| V | [`v/c/cone.v`](../../../v/c/cone.v) |
| Zig | [`zig/c/cone.zig`](../../../zig/c/cone.zig) |
