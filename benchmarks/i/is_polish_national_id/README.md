# Polish national ID check

Validate an 11-digit PESEL number using the field checks and weighted checksum implemented by the pinned Python source.

## Contract

The `i64_array_scalar` input is an unprefixed array of exactly 11 ASCII digit codes. Return `1` when the source's checks accept the PESEL, `0` when a well-formed digit string fails those checks, and `-1` for a malformed length or nondigit code.

The source's numeric range is 10,100,000 through 99,923,199,999. The encoded month must be in 1–12, 21–32, 41–52, 61–72, or 81–92, and the day field must be 1–31. The checksum applies weights `[1, 3, 7, 9]` cyclically to the first ten digits, adds each product's final decimal digit, then compares `10 - (subtotal mod 10)` with the last digit. The package preserves this exact source formula, including its result when the subtotal is divisible by ten.

This contract follows the source's month-code and day-range checks; it does not validate month-specific day counts or leap years. Leading zeroes are significant in the date fields and are retained by the code-array input.

## Source

The pinned Python [`is_polish_national_id.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/is_polish_national_id.py) checks the numeric range, encoded month, day range, and weighted check digit. Its string/type and parse exceptions are represented by the benchmark's explicit malformed-input result.

## Workload and recording

[`workload.json`](workload.json) covers valid PESEL examples, leading zeroes, out-of-range numbers, invalid encoded months and days, checksum mismatch, and malformed input.

The shared `i64_array_scalar` runner checks the source's numeric range, encoded month and day fields, and cyclic weighted checksum for each workload case.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm is_polish_national_id --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/i/is_polish_national_id/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/i/is_polish_national_id.c`](../../../c/i/is_polish_national_id.c) |
| C3 | [`c3/i/is_polish_national_id.c3`](../../../c3/i/is_polish_national_id.c3) |
| C++ | [`cpp/i/is_polish_national_id.cpp`](../../../cpp/i/is_polish_national_id.cpp) |
| Elisa | [`elisa/i/is_polish_national_id.elisa`](../../../elisa/i/is_polish_national_id.elisa) |
| Nim | [`nim/i/is_polish_national_id.nim`](../../../nim/i/is_polish_national_id.nim) |
| Odin | [`odin/i/is_polish_national_id.odin`](../../../odin/i/is_polish_national_id.odin) |
| Rust | [`rust/i/is_polish_national_id.rs`](../../../rust/i/is_polish_national_id.rs) |
| V | [`v/i/is_polish_national_id.v`](../../../v/i/is_polish_national_id.v) |
| Zig | [`zig/i/is_polish_national_id.zig`](../../../zig/i/is_polish_national_id.zig) |
