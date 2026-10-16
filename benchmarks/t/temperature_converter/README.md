# Temperature Converter

This benchmark ports the six direct conversion methods in the pinned Java `TemperatureConverter` class. It preserves each method's arithmetic expression order and returns the binary64 result without rounding.

## Contract

- The `i64_array_float64` input is `[operation, temperature_micro]`. `temperature_micro` represents the input temperature multiplied by 1,000,000.
- Operation codes are `0=Celsius to Fahrenheit`, `1=Celsius to Kelvin`, `2=Fahrenheit to Celsius`, `3=Fahrenheit to Kelvin`, `4=Kelvin to Celsius`, and `5=Kelvin to Fahrenheit`.
- Each temperature input is bounded to `[-1,000,000, 1,000,000]` in its source scale. The source methods do not validate physical temperatures, so negative Kelvin values are also accepted within this numeric bound.
- The adapter divides `temperature_micro` by `1,000,000.0` and then evaluates the selected pinned expression in source order. It does not round the result. The output is binary64 with absolute and relative tolerances of `1e-12`.
- Invalid packed input, an unsupported operation, or an out-of-bound temperature maps to `-1e300`. The parser admits three values so one extra packed value can reach the adapter.

## Pinned source

Java [`TemperatureConverter.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/TemperatureConverter.java) at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Workload and build

[`workload.json`](workload.json) covers all six conversions, common reference points, fractional inputs, both temperature bounds, invalid operations, and malformed packed input. The independent oracle is [`benchmarks/temperature_converter_oracle.py`](../../temperature_converter_oracle.py).

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm temperature_converter --language rust
python3 benchmarks/run_i64_array_float64.py --algorithm temperature_converter
python3 benchmarks/verify_i64_array_float64.py --algorithms temperature_converter
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/temperature_converter.c`](../../../c/t/temperature_converter.c) |
| C3 | [`c3/t/temperature_converter.c3`](../../../c3/t/temperature_converter.c3) |
| C++ | [`cpp/t/temperature_converter.cpp`](../../../cpp/t/temperature_converter.cpp) |
| Elisa | [`elisa/t/temperature_converter.elisa`](../../../elisa/t/temperature_converter.elisa) |
| Nim | [`nim/t/temperature_converter.nim`](../../../nim/t/temperature_converter.nim) |
| Odin | [`odin/t/temperature_converter.odin`](../../../odin/t/temperature_converter.odin) |
| Rust | [`rust/t/temperature_converter.rs`](../../../rust/t/temperature_converter.rs) |
| V | [`v/t/temperature_converter.v`](../../../v/t/temperature_converter.v) |
| Zig | [`zig/t/temperature_converter.zig`](../../../zig/t/temperature_converter.zig) |
