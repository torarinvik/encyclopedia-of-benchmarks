# Kelvin to Celsius

Convert a Kelvin input to Celsius using the pinned C++ function's binary64
addition order.

## Contract

- The input uses the `float64_unary` ABI and is a finite binary64 value in
  `[0, 1,000,000]` kelvins.
- Return `temperature_in_k + (-273.15)` as binary64. The implementation keeps
  the source's constant and addition expression.
- Inputs outside this bounded physical Kelvin domain return `-1.0`. That
  sentinel can equal a valid result at `272.15 K`; workload cases identify
  valid inputs explicitly.
- Results are compared with absolute error at most
  `1e-12 + 1e-15 * abs(expected)`.

## Pinned source

The pinned [C++ `kelvin_to_celsius.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/kelvin_to_celsius.cpp)
defines `absolute_zero_in_c` as `-273.15`, checks whether the input is below
that value, then returns `temperature_in_k + absolute_zero_in_c`. The check
allows some negative Kelvin values; this benchmark narrows inputs to the
physical nonnegative domain and an explicit upper bound. The source guard is
therefore not reached for supported values, and its conversion expression is
preserved.

## Workload and build

[`workload.json`](workload.json) includes the pinned examples, zero kelvins,
absolute zero, fractional inputs, and both bounds. Build and record with:

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm kelvin_to_celsius --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/k/kelvin_to_celsius/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/k/kelvin_to_celsius.c`](../../../c/k/kelvin_to_celsius.c) |
| C3 | [`c3/k/kelvin_to_celsius.c3`](../../../c3/k/kelvin_to_celsius.c3) |
| C++ | [`cpp/k/kelvin_to_celsius.cpp`](../../../cpp/k/kelvin_to_celsius.cpp) |
| Elisa | [`elisa/k/kelvin_to_celsius.elisa`](../../../elisa/k/kelvin_to_celsius.elisa) |
| Nim | [`nim/k/kelvin_to_celsius.nim`](../../../nim/k/kelvin_to_celsius.nim) |
| Odin | [`odin/k/kelvin_to_celsius.odin`](../../../odin/k/kelvin_to_celsius.odin) |
| Rust | [`rust/k/kelvin_to_celsius.rs`](../../../rust/k/kelvin_to_celsius.rs) |
| V | [`v/k/kelvin_to_celsius.v`](../../../v/k/kelvin_to_celsius.v) |
| Zig | [`zig/k/kelvin_to_celsius.zig`](../../../zig/k/kelvin_to_celsius.zig) |
