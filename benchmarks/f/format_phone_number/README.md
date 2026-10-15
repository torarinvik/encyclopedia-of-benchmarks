# Format phone number

## Contract

This benchmark follows the pinned JavaScript `formatPhoneNumber` function for
10-character ASCII decimal inputs. The source checks the input length and
numeric coercibility, then replaces the ten `X` characters in
`(XXX) XXX-XXXX` with the input characters from left to right. The benchmark
uses exactly ten ASCII digits, a subset that always passes the source check
and preserves leading zeroes and character order.

Input is an array of exactly ten signed 64-bit slots, each containing an ASCII
digit value from `0` through `9`. The function writes the 14 ASCII bytes of
`(XXX) XXX-XXXX` to the caller's output buffer and returns `14`. Invalid input
returns `-1` with no output bytes; insufficient output capacity returns `-2`.

The restricted digit domain avoids broader JavaScript `isNaN` coercion rules
for signs, decimal points, whitespace, and other numeric strings. This is a
formatter, distinct from the country-specific phone validators.

## Workload and build

[`workload.json`](workload.json) uses the `i64_array_bytes_output` ABI. It
covers leading zeroes, representative digit patterns, and invalid length or
bytes.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm format_phone_number --language c
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/f/format_phone_number/c/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/f/format_phone_number.c`](../../../c/f/format_phone_number.c) |
| C3 | [`c3/f/format_phone_number.c3`](../../../c3/f/format_phone_number.c3) |
| C++ | [`cpp/f/format_phone_number.cpp`](../../../cpp/f/format_phone_number.cpp) |
| Elisa | [`elisa/f/format_phone_number.elisa`](../../../elisa/f/format_phone_number.elisa) |
| Nim | [`nim/f/format_phone_number.nim`](../../../nim/f/format_phone_number.nim) |
| Odin | [`odin/f/format_phone_number.odin`](../../../odin/f/format_phone_number.odin) |
| Rust | [`rust/f/format_phone_number.rs`](../../../rust/f/format_phone_number.rs) |
| V | [`v/f/format_phone_number.v`](../../../v/f/format_phone_number.v) |
| Zig | [`zig/f/format_phone_number.zig`](../../../zig/f/format_phone_number.zig) |

## Pinned source

- JavaScript [`FormatPhoneNumber.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/FormatPhoneNumber.js)
