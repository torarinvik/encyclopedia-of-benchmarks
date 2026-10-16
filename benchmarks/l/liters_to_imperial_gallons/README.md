# Liters to Imperial gallons

Convert liters to Imperial gallons using the pinned JavaScript expression `liters / 4.54609`. The source returns the direct binary64 division result.

## Contract

- The `float64_unary` ABI accepts one finite IEEE 754 binary64 value in `[-1e100, 1e100]` and returns Imperial gallons.
- Finite values outside that range return `-1e300`.
- Valid inputs use the source's exact conversion factor and operation order: divide liters by `4.54609`. No rounding or additional unit conversion is applied.
- The workload compares results with relative and absolute tolerances of `1e-15`.

The bounded domain keeps results finite and reserves `-1e300` as the invalid sentinel. This is distinct from the U.S. liquid gallon conversion, which uses the factor `3.785411784`.

## Source

Pinned source: [TheAlgorithms/JavaScript `LitersToImperialGallons.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/LitersToImperialGallons.js).

## Workload and build

[`workload.json`](workload.json) covers zero, positive and negative volumes, one Imperial gallon, small and large magnitudes, both domain bounds, and out-of-range values. All nine ports use the shared `float64_unary` ABI.

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm liters_to_imperial_gallons --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/l/liters_to_imperial_gallons/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/l/liters_to_imperial_gallons.c`](../../../c/l/liters_to_imperial_gallons.c) |
| C3 | [`c3/l/liters_to_imperial_gallons.c3`](../../../c3/l/liters_to_imperial_gallons.c3) |
| C++ | [`cpp/l/liters_to_imperial_gallons.cpp`](../../../cpp/l/liters_to_imperial_gallons.cpp) |
| Elisa | [`elisa/l/liters_to_imperial_gallons.elisa`](../../../elisa/l/liters_to_imperial_gallons.elisa) |
| Nim | [`nim/l/liters_to_imperial_gallons.nim`](../../../nim/l/liters_to_imperial_gallons.nim) |
| Odin | [`odin/l/liters_to_imperial_gallons.odin`](../../../odin/l/liters_to_imperial_gallons.odin) |
| Rust | [`rust/l/liters_to_imperial_gallons.rs`](../../../rust/l/liters_to_imperial_gallons.rs) |
| V | [`v/l/liters_to_imperial_gallons.v`](../../../v/l/liters_to_imperial_gallons.v) |
| Zig | [`zig/l/liters_to_imperial_gallons.zig`](../../../zig/l/liters_to_imperial_gallons.zig) |
