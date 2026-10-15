# Leap year

## Contract

Input is a signed 64-bit year. Positive years use the Gregorian calendar: return `1` when the year is divisible by 400, or divisible by 4 but not by 100; return `0` otherwise. Zero and negative years are invalid and return `-1`.

The JavaScript source applies the Gregorian divisibility rule without validating the year. The TypeScript source explicitly requires a natural number greater than zero. This benchmark uses their shared positive-year domain and gives invalid input a stable integer result.

## Workload and reproduction

The workload covers the ordinary 4-year rule, century exceptions, 400-year exceptions, current years, invalid years, and signed 64-bit upper-bound cases. Build a port with the scalar ABI:

```sh
python3 benchmarks/build_scalar.py --algorithm leap_year --language rust
```

The build manifest is written to `build/scalar/l/leap_year/rust/build.json`. Independent runtime verification remains pending.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/l/leap_year.c`](../../../c/l/leap_year.c) |
| C3 | [`c3/l/leap_year.c3`](../../../c3/l/leap_year.c3) |
| C++ | [`cpp/l/leap_year.cpp`](../../../cpp/l/leap_year.cpp) |
| Elisa | [`elisa/l/leap_year.elisa`](../../../elisa/l/leap_year.elisa) |
| Nim | [`nim/l/leap_year.nim`](../../../nim/l/leap_year.nim) |
| Odin | [`odin/l/leap_year.odin`](../../../odin/l/leap_year.odin) |
| Rust | [`rust/l/leap_year.rs`](../../../rust/l/leap_year.rs) |
| V | [`v/l/leap_year.v`](../../../v/l/leap_year.v) |
| Zig | [`zig/l/leap_year.zig`](../../../zig/l/leap_year.zig) |

## TheAlgorithms references

- [JavaScript `LeapYear.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/LeapYear.js)
- [TypeScript `is_leap_year.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/is_leap_year.ts)
