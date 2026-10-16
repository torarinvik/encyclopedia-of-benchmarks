# Liters to U.S. Gallons

Convert one volume in liters to U.S. liquid gallons using the pinned JavaScript source expression `liters / 3.785411784`. The source accepts a JavaScript number and returns the direct binary64 division result.

## Contract

- The `float64_unary` ABI accepts one finite IEEE 754 binary64 value in `[-1e100, 1e100]` and returns binary64 U.S. liquid gallons.
- Finite values outside that range return `-1e300`.
- Valid inputs use the source's exact conversion factor and operation order: divide liters by `3.785411784`. No rounding or unit conversion beyond that division is added.
- The workload compares outputs with relative and absolute tolerances of `1e-15`.

The bound keeps the result finite and leaves the invalid sentinel outside the valid result range. The Imperial gallon conversion is a separate algorithm and uses a different factor.

## Source

The package follows the pinned [TheAlgorithms/JavaScript `LitersToUSGallons.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/LitersToUSGallons.js).

## Workload and build

[`workload.json`](workload.json) covers zero, positive and negative volumes, the exact one-U.S.-gallon reference, small and large magnitudes, both domain bounds, and out-of-range values. All nine ports use the shared `float64_unary` ABI.

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm liters_to_usgallons --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/l/liters_to_usgallons/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/l/liters_to_usgallons.c`](../../../c/l/liters_to_usgallons.c) |
| C3 | [`c3/l/liters_to_usgallons.c3`](../../../c3/l/liters_to_usgallons.c3) |
| C++ | [`cpp/l/liters_to_usgallons.cpp`](../../../cpp/l/liters_to_usgallons.cpp) |
| Elisa | [`elisa/l/liters_to_usgallons.elisa`](../../../elisa/l/liters_to_usgallons.elisa) |
| Nim | [`nim/l/liters_to_usgallons.nim`](../../../nim/l/liters_to_usgallons.nim) |
| Odin | [`odin/l/liters_to_usgallons.odin`](../../../odin/l/liters_to_usgallons.odin) |
| Rust | [`rust/l/liters_to_usgallons.rs`](../../../rust/l/liters_to_usgallons.rs) |
| V | [`v/l/liters_to_usgallons.v`](../../../v/l/liters_to_usgallons.v) |
| Zig | [`zig/l/liters_to_usgallons.zig`](../../../zig/l/liters_to_usgallons.zig) |
