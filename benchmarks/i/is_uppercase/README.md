# Is uppercase

Checks the pinned R routine's uppercase comparison over a printable ASCII string.

## Contract

- Uses `i64_array_scalar`; each array element is one printable ASCII code value in `32..126`.
- The array length is `0..4096`.
- Return `1` if every character is unchanged by ASCII uppercase conversion, otherwise `0`.
- Equivalently on this domain, return `0` if any lowercase ASCII letter (`a`–`z`) occurs; digits, punctuation, and spaces pass.
- The empty string returns `1`, matching R's `all(logical(0))` behavior.
- Invalid lengths or code values return `-1`.

## Source semantics

This follows pinned [TheAlgorithms R `is.uppercase.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/string_manipulation/is.uppercase.r). It splits the string into characters, compares the result with `toupper` applied character by character, and calls `all` on those comparisons. The benchmark limits input to printable ASCII so R's locale and Unicode case mapping do not vary between the nine ports. Despite the source function's “is uppercase” name, it accepts every character that is already unchanged by uppercase conversion, including nonletters.

This is distinct from [`is_lower`](../is_lower/README.md): `is_lower` rejects uppercase ASCII letters, while this predicate rejects lowercase ASCII letters. Mixed-case input fails both.

## Workload and build

[`workload.json`](workload.json) includes uppercase text, lowercase letters, mixed case, digits, punctuation, whitespace, empty input, and malformed values. Build and record with the existing array scalar ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm is_uppercase --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/i/is_uppercase/rust/build.json
```

The nine implementations are in `c/i/is_uppercase.c`, `c3/i/is_uppercase.c3`, `cpp/i/is_uppercase.cpp`, `elisa/i/is_uppercase.elisa`, `nim/i/is_uppercase.nim`, `odin/i/is_uppercase.odin`, `rust/i/is_uppercase.rs`, `v/i/is_uppercase.v`, and `zig/i/is_uppercase.zig`.
