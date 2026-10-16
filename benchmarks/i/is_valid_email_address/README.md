# Is valid email address

This benchmark preserves the pinned Python function's ASCII address checks. It
does not implement the full email standards.

## Contract

- Input is an `i64_array_scalar` array of Unicode code points for one string.
- Arrays longer than 320 code points return `0` immediately. For shorter arrays,
  code points outside `0..=0x10FFFF` are malformed ABI input and return `-1`;
  valid code points return `1` for true and `0` for false.
- There must be exactly one `@`. The local part may be empty and is at most 64
  characters; the domain may be empty and is at most 255 characters.
- The local part accepts ASCII letters, digits, and
  ``.!#$%&'*+-/=?^_`{|}~()``. A dot cannot be first, last, or adjacent to another
  dot.
- The domain accepts ASCII letters, digits, dots, and hyphens. Dots cannot be
  first, last, or adjacent to another dot. The source rejects a leading hyphen,
  but its implementation does not reject a trailing hyphen despite the docstring.
- Consequently, source quirks such as `@`, `user@`, and `user@example-` return
  true. These are retained for parity. A full input longer than 320 code points
  cannot satisfy both component limits and returns false; that length check has
  precedence over malformed-code-point checks.

The source's character allowlists make all non-ASCII characters invalid. The
64/255 limits therefore equal the maximum accepted ASCII octet counts.

## Workload

[`workload.json`](workload.json) covers the pinned examples, boundary lengths,
empty components, allowed local punctuation, dot placement, domain hyphen
behavior, invalid characters, and malformed code-point values.

## Pinned source

- [TheAlgorithms/Python `is_valid_email_address.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/is_valid_email_address.py)

## Build and verification

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm is_valid_email_address --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/i/is_valid_email_address/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms is_valid_email_address --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/is_valid_email_address.c`](../../../c/i/is_valid_email_address.c) |
| C3 | [`c3/i/is_valid_email_address.c3`](../../../c3/i/is_valid_email_address.c3) |
| C++ | [`cpp/i/is_valid_email_address.cpp`](../../../cpp/i/is_valid_email_address.cpp) |
| Elisa | [`elisa/i/is_valid_email_address.elisa`](../../../elisa/i/is_valid_email_address.elisa) |
| Nim | [`nim/i/is_valid_email_address.nim`](../../../nim/i/is_valid_email_address.nim) |
| Odin | [`odin/i/is_valid_email_address.odin`](../../../odin/i/is_valid_email_address.odin) |
| Rust | [`rust/i/is_valid_email_address.rs`](../../../rust/i/is_valid_email_address.rs) |
| V | [`v/i/is_valid_email_address.v`](../../../v/i/is_valid_email_address.v) |
| Zig | [`zig/i/is_valid_email_address.zig`](../../../zig/i/is_valid_email_address.zig) |
