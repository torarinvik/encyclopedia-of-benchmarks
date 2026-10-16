# Time Converter

This benchmark ports the pinned Java [`TimeConverter.convertTime`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/TimeConverter.java) method. It converts a nonnegative time value through seconds, then rounds the target-unit value to three decimal places.

## Contract

- The `i64_array_float64` input is `[time_micro, from_unit, to_unit]`. `time_micro` uses 1,000,000 integer units per source time value. Unit selectors are `0=seconds`, `1=minutes`, `2=hours`, `3=days`, `4=weeks`, `5=months`, and `6=years`.
- The value is bounded to `[0, 1,000]`; both unit selectors must be in `[0, 6]`. The adapter maps the source's case-insensitive supported unit names to these selectors before the measured conversion call.
- The pinned factors in seconds are `1`, `60`, `3,600`, `86,400`, `604,800`, `2,629,800` (30.44 days), and `31,557,600` (365.25 days). The source operation order is preserved: multiply by the source factor, divide by the target factor, then apply `Math.round(converted * 1000) / 1000` semantics. Inputs are nonnegative, so ports use truncation of `converted * 1000 + 0.5` to match Java rounding.
- Invalid packed input, negative or over-bound time values, and unsupported unit selectors map to `-1e300`. The parser admits four values so an extra packed value can reach the adapter.

## Pinned source

Java [`TimeConverter.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/TimeConverter.java) at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Workload and build

[`workload.json`](workload.json) covers every unit factor, conversion in both directions, three-decimal rounding boundaries, the maximum value, and invalid input. The independent oracle is [`time_converter_oracle.py`](../../time_converter_oracle.py).

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm time_converter --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/t/time_converter/rust/build.json
python3 benchmarks/verify_i64_array_float64.py --algorithms time_converter
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/time_converter.c`](../../../c/t/time_converter.c) |
| C3 | [`c3/t/time_converter.c3`](../../../c3/t/time_converter.c3) |
| C++ | [`cpp/t/time_converter.cpp`](../../../cpp/t/time_converter.cpp) |
| Elisa | [`elisa/t/time_converter.elisa`](../../../elisa/t/time_converter.elisa) |
| Nim | [`nim/t/time_converter.nim`](../../../nim/t/time_converter.nim) |
| Odin | [`odin/t/time_converter.odin`](../../../odin/t/time_converter.odin) |
| Rust | [`rust/t/time_converter.rs`](../../../rust/t/time_converter.rs) |
| V | [`v/t/time_converter.v`](../../../v/t/time_converter.v) |
| Zig | [`zig/t/time_converter.zig`](../../../zig/t/time_converter.zig) |
