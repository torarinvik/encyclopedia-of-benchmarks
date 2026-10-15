# String is valid number

Checks whether a character sequence represents an integer, decimal, or exponent using the pinned finite-state machine.

## Contract

- Uses the `i64_array_scalar` ABI. Each array element is one ASCII byte value, and the array is the complete string.
- Lengths from 0 through 256 are accepted. Valid numeric strings return `1`; other ASCII strings return `0`.
- Lengths above 256, a null pointer with nonzero length, or an element outside ASCII `[0, 127]` return `-1`.
- The accepted grammar allows an optional leading sign; digits with an optional decimal point; or a decimal/exponent form using `e` or `E`, optionally followed by a sign and at least one digit.

## Source semantics

The benchmark follows pinned [TheAlgorithms Python `string_is_valid_number.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/string_is_valid_number.py). It classifies digits, signs, decimal points, and exponent markers, then advances through eight states. Only `WHOLE`, `FRACTION`, and `EXP_NUMBER` are accepting states. Empty input ends in `INITIAL` and returns false. The benchmark restricts inputs to ASCII, where Python's `str.isdigit()` agrees with the ASCII digit range; Unicode digit extensions are outside the contract.

This parser validates a complete numeric string. It is distinct from `c_atoi_str_to_integer`, which parses a leading integer prefix and may stop at following characters.

## Workload and build

[`workload.json`](workload.json) covers integers, decimal forms, exponents, empty input, malformed syntax, and the non-ASCII contract boundary. Build and record with the array-scalar ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm string_is_valid_number --language c
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/s/string_is_valid_number/c/build.json
```

The nine implementations are in `c/s/string_is_valid_number.c`, `c3/s/string_is_valid_number.c3`, `cpp/s/string_is_valid_number.cpp`, `elisa/s/string_is_valid_number.elisa`, `nim/s/string_is_valid_number.nim`, `odin/s/string_is_valid_number.odin`, `rust/s/string_is_valid_number.rs`, `v/s/string_is_valid_number.v`, and `zig/s/string_is_valid_number.zig`.
