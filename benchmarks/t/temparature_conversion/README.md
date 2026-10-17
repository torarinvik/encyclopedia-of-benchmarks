# Rounded Temperature Conversion

This package ports the six direct conversion functions in the pinned [TheAlgorithms/Julia `temparature_conversion.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/conversions/temparature_conversion.jl). It preserves each formula's expression order and Julia's decimal rounding.

## Contract

The `i64_array_float64` input is exactly `[operation, temperature_micro, ndigits]`. Operations `0..5` are Celsius→Fahrenheit, Celsius→Kelvin, Fahrenheit→Celsius, Fahrenheit→Kelvin, Kelvin→Celsius, and Kelvin→Fahrenheit. `temperature_micro` is divided by 1,000,000 to produce the source temperature and is bounded to ±1,000,000,000,000; `ndigits` is bounded to `-6..6`. A value of `2` represents the source's default precision.

The selected source formula is evaluated in its original Float64 operation order, then rounded to `ndigits` decimal places using Julia's default `RoundNearest` behavior (ties to even). Negative `ndigits` rounds before the decimal point. The result is binary64; absolute and relative comparison tolerances are both `1e-12`. Invalid framing, operation, temperature, or digit count returns `-1e300`. The valid input has three values; ports accept a fourth value so extra-payload cases are rejected explicitly.

The six expressions are:

| Operation | Source expression |
| --- | --- |
| 0 | `temperature * 1.8 + 32.0` |
| 1 | `temperature + 273.15` |
| 2 | `(temperature - 32.0) * 5 / 9` |
| 3 | `((temperature - 32.0) * 5 / 9) + 273.15` |
| 4 | `temperature - 273.15` |
| 5 | `((temperature - 273.15) * 1.8) + 32.0` |

This is distinct from the Java `temperature_converter` package, which leaves these six direct formulas unrounded; the JavaScript `temperature_conversion` package, which rounds whole degrees ties toward positive infinity; and the Rust `temperature` package, which converts through Kelvin among eight scales.

## Workload and oracle

[`workload.json`](workload.json) covers all six operations, the default precision, positive and negative temperatures, decimal and integer rounding, a ties-to-even case, both temperature bounds, and malformed inputs. [`temparature_conversion_oracle.py`](../../temparature_conversion_oracle.py) preserves the formula order and decimal ties-to-even behavior.

## Language ports

- C: [`c/t/temparature_conversion.c`](../../../c/t/temparature_conversion.c)
- C3: [`c3/t/temparature_conversion.c3`](../../../c3/t/temparature_conversion.c3)
- C++: [`cpp/t/temparature_conversion.cpp`](../../../cpp/t/temparature_conversion.cpp)
- Elisa: [`elisa/t/temparature_conversion.elisa`](../../../elisa/t/temparature_conversion.elisa)
- Nim: [`nim/t/temparature_conversion.nim`](../../../nim/t/temparature_conversion.nim)
- Odin: [`odin/t/temparature_conversion.odin`](../../../odin/t/temparature_conversion.odin)
- Rust: [`rust/t/temparature_conversion.rs`](../../../rust/t/temparature_conversion.rs)
- V: [`v/t/temparature_conversion.v`](../../../v/t/temparature_conversion.v)
- Zig: [`zig/t/temparature_conversion.zig`](../../../zig/t/temparature_conversion.zig)
