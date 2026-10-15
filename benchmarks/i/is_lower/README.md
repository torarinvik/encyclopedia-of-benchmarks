# Is lower

Checks the pinned R routine's lowercase comparison over a printable ASCII string.

## Contract

- Uses `i64_array_scalar`; each array element is one printable ASCII code value in `32..126`.
- The array length is `0..4096`.
- Return `1` if every character is unchanged by ASCII lowercase conversion, otherwise `0`.
- Equivalently on this domain, return `0` if any uppercase ASCII letter (`A`–`Z`) occurs; digits, punctuation, and spaces pass.
- The empty string returns `1`, matching R's `all(logical(0))` behavior.
- Invalid lengths or code values return `-1`.

## Source semantics

This follows pinned [TheAlgorithms R `is.lower.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/string_manipulation/is.lower.r). It splits the string into characters, compares the result with `tolower` applied character by character, and calls `all` on those comparisons. The benchmark limits input to printable ASCII so R's locale and Unicode case mapping do not vary between the nine ports. Despite the source function's “is lowercase” name, it accepts every character that is already unchanged by lowercase conversion, including nonletters.

## Workload and build

[`workload.json`](workload.json) includes lowercase text, uppercase letters, mixed case, digits, punctuation, whitespace, empty input, and malformed values. Build and record with the existing array scalar ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm is_lower --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/i/is_lower/rust/build.json
```

The nine implementations are in `c/i/is_lower.c`, `c3/i/is_lower.c3`, `cpp/i/is_lower.cpp`, `elisa/i/is_lower.elisa`, `nim/i/is_lower.nim`, `odin/i/is_lower.odin`, `rust/i/is_lower.rs`, `v/i/is_lower.v`, and `zig/i/is_lower.zig`.
