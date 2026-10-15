# Altitude from pressure

Estimates altitude above sea level from atmospheric pressure in pascals using the pinned Python source's barometric approximation.

## Contract

- Uses the one-input binary64 ABI: `double altitude_pressure(double pressure)`.
- Valid pressure is finite and in `[0, 101325]` Pa, inclusive.
- For valid pressure, return `44330 * (1 - (pressure / 101325) ** (1 / 5.5255))` metres. Pressure zero returns `44330`; sea-level pressure returns zero.
- Values outside the valid range map to `-1.0`. The source raises `ValueError` for pressure below zero or above sea-level reference pressure; the scalar ABI uses this sentinel so all ports share one result contract.
- Compare results with relative tolerance `1e-12` and absolute tolerance `1e-10`.

## Source semantics

The benchmark follows the pinned [TheAlgorithms Python `altitude_pressure.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/altitude_pressure.py). Its docstring gives the exponent denominator as `5.255`, but the returned expression in the source code uses `5.5255`; all ports follow the executable expression. The source rejects negative pressure and pressure above `101325` Pa. The shared scalar ABI maps those exceptions to `-1.0` and retains the source formula on the valid domain.

## Workload and build

[`workload.json`](workload.json) includes zero, sea-level pressure, representative lower pressures, near-boundary values, and inputs outside the source domain. Build with the `float64_unary` ABI family and record with `benchmarks/run_float64_unary.py`:

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm altitude_pressure --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/a/altitude_pressure/rust/build.json
```

The nine implementations are in `c/a/altitude_pressure.c`, `c3/a/altitude_pressure.c3`, `cpp/a/altitude_pressure.cpp`, `elisa/a/altitude_pressure.elisa`, `nim/a/altitude_pressure.nim`, `odin/a/altitude_pressure.odin`, `rust/a/altitude_pressure.rs`, `v/a/altitude_pressure.v`, and `zig/a/altitude_pressure.zig`.
