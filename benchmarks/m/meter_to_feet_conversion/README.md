# Meter to feet conversion

Benchmark the two conversion functions exported by the pinned [TheAlgorithms JavaScript source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/MeterToFeetConversion.js): feet to meters and meters to feet.

## Contract

- The `i64_array_float64` ABI accepts `[operation, milliunits]` and returns a binary64 converted value.
- Operation `0` converts feet to meters using `(milliunits / 1000.0) * 0.3048`, matching `feetToMeter`. Operation `1` converts meters to feet using `(milliunits / 1000.0) / 0.3048`, matching `meterToFeet`.
- Inputs are signed integer milli-feet or milli-meters, bounded to -1,000,000,000 through 1,000,000,000. Negative and zero inputs are valid because the source functions perform direct arithmetic without validation.
- Unsupported operations, malformed lengths, and out-of-range values return `-1e300`. Valid outputs use relative and absolute tolerances of `1e-12`.

[`workload.json`](workload.json) includes source unit examples, fractional quantities, negative values, range endpoints, and invalid inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/meter_to_feet_conversion.c`](../../../c/m/meter_to_feet_conversion.c) |
| C3 | [`c3/m/meter_to_feet_conversion.c3`](../../../c3/m/meter_to_feet_conversion.c3) |
| C++ | [`cpp/m/meter_to_feet_conversion.cpp`](../../../cpp/m/meter_to_feet_conversion.cpp) |
| Elisa | [`elisa/m/meter_to_feet_conversion.elisa`](../../../elisa/m/meter_to_feet_conversion.elisa) |
| Nim | [`nim/m/meter_to_feet_conversion.nim`](../../../nim/m/meter_to_feet_conversion.nim) |
| Odin | [`odin/m/meter_to_feet_conversion.odin`](../../../odin/m/meter_to_feet_conversion.odin) |
| Rust | [`rust/m/meter_to_feet_conversion.rs`](../../../rust/m/meter_to_feet_conversion.rs) |
| V | [`v/m/meter_to_feet_conversion.v`](../../../v/m/meter_to_feet_conversion.v) |
| Zig | [`zig/m/meter_to_feet_conversion.zig`](../../../zig/m/meter_to_feet_conversion.zig) |
