# Temperature conversion

Convert integer temperatures among Celsius, Fahrenheit, Kelvin, Rankine, and Réaumur using the pinned JavaScript implementation's 16 directed conversions. The returned value is rounded to a whole degree.

## Contract

The `i64_array_scalar` input is `[operation, temperature]`. Operations are numbered as follows: `0` C→F, `1` C→K, `2` C→Rankine, `3` F→C, `4` F→K, `5` F→Rankine, `6` K→C, `7` K→F, `8` K→Rankine, `9` Rankine→C, `10` Rankine→F, `11` Rankine→K, `12` Réaumur→C, `13` Réaumur→F, `14` Réaumur→K, and `15` Réaumur→Rankine. Temperature inputs must be in `[-1,000,000, 1,000,000]`; malformed arrays, operation codes, or temperatures return `I64_MIN`.

Each operation uses the pinned formula and expression order. The result follows JavaScript `Math.round` behavior, equivalent to `floor(value + 0.5)` for this bounded finite domain, so halfway values round toward positive infinity. This contract records integer input and whole-degree output; it is distinct from the decimal-valued `temperature_conversions` and `temperature_converter` packages.

## Source

The pinned JavaScript [`TemperatureConversion.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/TemperatureConversion.js) defines these directed conversions and applies `Math.round` to each result.

## Workload and recording

[`workload.json`](workload.json) covers all 16 operations, negative and nonzero values, invalid operation and temperature bounds, and malformed array lengths.

The source-backed oracle in [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py) evaluates each conversion using the pinned expression order and JavaScript `Math.round` semantics.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm temperature_conversion --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/t/temperature_conversion/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/t/temperature_conversion.c`](../../../c/t/temperature_conversion.c) |
| C3 | [`c3/t/temperature_conversion.c3`](../../../c3/t/temperature_conversion.c3) |
| C++ | [`cpp/t/temperature_conversion.cpp`](../../../cpp/t/temperature_conversion.cpp) |
| Elisa | [`elisa/t/temperature_conversion.elisa`](../../../elisa/t/temperature_conversion.elisa) |
| Nim | [`nim/t/temperature_conversion.nim`](../../../nim/t/temperature_conversion.nim) |
| Odin | [`odin/t/temperature_conversion.odin`](../../../odin/t/temperature_conversion.odin) |
| Rust | [`rust/t/temperature_conversion.rs`](../../../rust/t/temperature_conversion.rs) |
| V | [`v/t/temperature_conversion.v`](../../../v/t/temperature_conversion.v) |
| Zig | [`zig/t/temperature_conversion.zig`](../../../zig/t/temperature_conversion.zig) |
