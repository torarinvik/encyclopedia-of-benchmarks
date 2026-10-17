# Temperature conversions

This benchmark extracts five direct conversions shared by the pinned PHP, Python, and Ruby sources. It excludes Fahrenheit-to-Kelvin because the pinned Ruby method omits the `+273.15` offset. The source functions round to one or two decimal places; the bounded input lattice makes their shared results identical.

## Contract

The `i64_array_float64` input is `[operation, temperature_micro]`, with `temperature = temperature_micro / 1,000,000`. The packed length must be exactly two values. Inputs are bounded to `[-1,000,000, 1,000,000]` in the relevant source scale. Operation codes and valid input lattices are:

| Code | Conversion | Valid source temperature |
|---:|---|---|
| 0 | Celsius to Fahrenheit | Multiples of 5 degrees |
| 1 | Fahrenheit to Celsius | `32 + 9k` degrees |
| 2 | Celsius to Kelvin | Integer degrees Celsius |
| 3 | Kelvin to Celsius | `273.15 + k` kelvin |
| 4 | Kelvin to Fahrenheit | `273.15 + 5k` kelvin |

Here `k` is any integer whose scaled input remains within the bound. These lattices make the PHP one-decimal C/F rounding agree with the two-decimal Python and Ruby rounding, and ensure the other shared conversions also agree after rounding. The source APIs accept numeric values; this integer-array ABI cannot represent their string-input errors. Invalid operation, bound, lattice, or packed length returns `-1e300`.

The output is binary64 with absolute and relative tolerance `1e-12`. The Ruby methods print a formatted line; this benchmark returns the numeric conversion value before display formatting.

[`workload.json`](workload.json) covers all five modes, the source examples, negative values, lattice boundaries, invalid modes, non-lattice values, and malformed arrays. The independent [oracle](../../temperature_conversions_oracle.py) validates the shared contract and returns the source-rounded result.

## Pinned sources

- [TheAlgorithms/PHP `TemperatureConversions.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Conversions/TemperatureConversions.php)
- [TheAlgorithms/Python `temperature_conversions.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/temperature_conversions.py)
- [TheAlgorithms/Ruby `temperature_conversions.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/conversions/temperature_conversions.rb)

## Implementations

| Language | Source |
|---|---|
| C | [`c/t/temperature_conversions.c`](../../../c/t/temperature_conversions.c) |
| C3 | [`c3/t/temperature_conversions.c3`](../../../c3/t/temperature_conversions.c3) |
| C++ | [`cpp/t/temperature_conversions.cpp`](../../../cpp/t/temperature_conversions.cpp) |
| Elisa | [`elisa/t/temperature_conversions.elisa`](../../../elisa/t/temperature_conversions.elisa) |
| Nim | [`nim/t/temperature_conversions.nim`](../../../nim/t/temperature_conversions.nim) |
| Odin | [`odin/t/temperature_conversions.odin`](../../../odin/t/temperature_conversions.odin) |
| Rust | [`rust/t/temperature_conversions.rs`](../../../rust/t/temperature_conversions.rs) |
| V | [`v/t/temperature_conversions.v`](../../../v/t/temperature_conversions.v) |
| Zig | [`zig/t/temperature_conversions.zig`](../../../zig/t/temperature_conversions.zig) |
