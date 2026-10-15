# Validate email

## Contract

This benchmark follows the pinned JavaScript expression `/^[^\s@]+@[^\s@]+\.[^\s@]+$/`. It returns true when an ASCII string has one `@`, nonempty characters on both sides, and at least one dot in the domain with a nonempty prefix and suffix. Every matched character must be outside JavaScript's whitespace set and must not be `@`. The expression does not enforce conventional email rules: it accepts punctuation, leading/trailing or repeated dots, and embedded NUL bytes.

The signed 64-bit input is `[length, ASCII_codepoints...]`. Length is 1..1,024; codes are 0..127. The explicit byte range makes the JavaScript `\s` rule portable: ASCII whitespace is tab, LF, vertical tab, form feed, CR, and space. JavaScript's `$` assertion also matches immediately before one final LF or CR, so a single trailing LF or CR is accepted; a trailing CRLF pair is rejected because the CR remains unmatched whitespace. Empty strings throw in the source and map to `-1`; malformed packing and non-ASCII values also map to `-1`. Valid input returns `1` or `0`.

This is distinct from TheAlgorithms Python `is_valid_email_address`: that candidate checks a stricter local/domain character grammar and length limits, and accepts `admin@mailserver1` without a domain dot. Existing `is_lower`, `is_uppercase`, and `check_snake_case` benchmarks validate character properties or a regex fragment, not email structure.

## Workload and implementations

[`workload.json`](workload.json) covers a conventional address, regex-accepted unusual punctuation, the required domain dot, ASCII whitespace, the final-line-terminator behavior, NUL, and invalid packing. The standard `i64_array_scalar` runner needs a `validate_email` oracle case before it can record this workload; aggregate and runner files are unchanged here.

| Language | Source |
| --- | --- |
| C | [`c/v/validate_email.c`](../../../c/v/validate_email.c) |
| C3 | [`c3/v/validate_email.c3`](../../../c3/v/validate_email.c3) |
| C++ | [`cpp/v/validate_email.cpp`](../../../cpp/v/validate_email.cpp) |
| Elisa | [`elisa/v/validate_email.elisa`](../../../elisa/v/validate_email.elisa) |
| Nim | [`nim/v/validate_email.nim`](../../../nim/v/validate_email.nim) |
| Odin | [`odin/v/validate_email.odin`](../../../odin/v/validate_email.odin) |
| Rust | [`rust/v/validate_email.rs`](../../../rust/v/validate_email.rs) |
| V | [`v/v/validate_email.v`](../../../v/v/validate_email.v) |
| Zig | [`zig/v/validate_email.zig`](../../../zig/v/validate_email.zig) |

## Pinned sources

- [JavaScript `ValidateEmail.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/ValidateEmail.js)
- [Python `is_valid_email_address.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/is_valid_email_address.py)
