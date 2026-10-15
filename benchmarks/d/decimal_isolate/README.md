# Decimal isolate

Return the positive fractional portion of a bounded binary64 value. The contract selects the common, unrounded behavior of the pinned JavaScript and Python sources.

## Contract

- Input is one finite binary64 value in `(0, 999999]` with a nonzero fractional part.
- The value must lie exactly on the four-decimal grid: `m = value * 10000` is an integer and `m` is divisible by `625`. This makes the value exactly representable in binary64 and keeps Python subtraction aligned with JavaScript's decimal-string extraction.
- The output is `(m mod 10000) / 10000`, the fractional part in `[0, 1)`. Integers, negative values, inexact binary decimals such as `0.1`, and values outside the range return `-1.0`.

## Source normalization

The pinned [JavaScript `decimalIsolate`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/DecimalIsolate.js) extracts the digits after the decimal point from `number.toString()` and parses them as a positive fraction. The pinned [Python `decimal_isolate`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/decimal_isolate.py) computes `number - int(number)` and optionally rounds to a requested number of digits. This benchmark fixes Python's `digit_amount` to zero and restricts inputs to positive exact-binary decimals with at most four places. Negative values and rounded results are excluded because the two source APIs differ there.

[`workload.json`](workload.json) covers exact binary fractions at different magnitudes, zero and integer inputs, negative values, inexact decimals, and the range bounds. The shared `float64_unary` oracle checks the exact four-place input restriction and fractional output.

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm decimal_isolate --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/d/decimal_isolate/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [c/d/decimal_isolate.c](../../../c/d/decimal_isolate.c) |
| C3 | [c3/d/decimal_isolate.c3](../../../c3/d/decimal_isolate.c3) |
| C++ | [cpp/d/decimal_isolate.cpp](../../../cpp/d/decimal_isolate.cpp) |
| Elisa | [elisa/d/decimal_isolate.elisa](../../../elisa/d/decimal_isolate.elisa) |
| Nim | [nim/d/decimal_isolate.nim](../../../nim/d/decimal_isolate.nim) |
| Odin | [odin/d/decimal_isolate.odin](../../../odin/d/decimal_isolate.odin) |
| Rust | [rust/d/decimal_isolate.rs](../../../rust/d/decimal_isolate.rs) |
| V | [v/d/decimal_isolate.v](../../../v/d/decimal_isolate.v) |
| Zig | [zig/d/decimal_isolate.zig](../../../zig/d/decimal_isolate.zig) |
