# Spain national ID check letter

Validate the control letter on a Spain national identity number (DNI) using the modulus-23 lookup used by the pinned Python source.

## Contract

The `i64_array_scalar` input is an unprefixed array of ASCII code points. Accept either eight decimal digits followed by one ASCII letter, or eight digits, one hyphen, and one ASCII letter. The final letter may be lowercase or uppercase. Return `1` when it matches the check-letter table at `number mod 23`, `0` when the format is valid but the letter does not match, and `-1` for malformed length, character codes, or format.

The check-letter table is `TRWAGMYFPDXBNJZSQVHLCKE`. The bounded contract covers the common undashed and `12345678-Z` display forms. The pinned source removes hyphens before validation; this package restricts the optional hyphen to the position before the letter and restricts characters to ASCII.

## Source

The pinned Python [`is_spain_national_id.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/is_spain_national_id.py) uppercases the input, parses the eight-digit number, and checks its remainder against the 23-letter table. This package maps the source's format exceptions to the ABI's `-1` result.

## Workload and recording

[`workload.json`](workload.json) covers the source example, lowercase and dashed forms, leading zeroes, an incorrect letter, malformed lengths, invalid digits, and invalid separators.

The shared `i64_array_scalar` runner checks each declared result with a source-specific modulus-23 oracle for this bounded contract.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm is_spain_national_id --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/i/is_spain_national_id/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/i/is_spain_national_id.c`](../../../c/i/is_spain_national_id.c) |
| C3 | [`c3/i/is_spain_national_id.c3`](../../../c3/i/is_spain_national_id.c3) |
| C++ | [`cpp/i/is_spain_national_id.cpp`](../../../cpp/i/is_spain_national_id.cpp) |
| Elisa | [`elisa/i/is_spain_national_id.elisa`](../../../elisa/i/is_spain_national_id.elisa) |
| Nim | [`nim/i/is_spain_national_id.nim`](../../../nim/i/is_spain_national_id.nim) |
| Odin | [`odin/i/is_spain_national_id.odin`](../../../odin/i/is_spain_national_id.odin) |
| Rust | [`rust/i/is_spain_national_id.rs`](../../../rust/i/is_spain_national_id.rs) |
| V | [`v/i/is_spain_national_id.v`](../../../v/i/is_spain_national_id.v) |
| Zig | [`zig/i/is_spain_national_id.zig`](../../../zig/i/is_spain_national_id.zig) |
