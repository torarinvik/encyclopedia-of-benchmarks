# Hexadecimal to Binary Digits

This package reproduces the pinned helper's numeric result for a bounded ASCII hexadecimal string. Input is the string's ASCII byte values in a signed 64-bit array: an optional leading `-`, followed by one through four hexadecimal digits. Uppercase and lowercase digits are accepted. Prefixes, whitespace, a leading `+`, and any other character are outside the contract and return the invalid sentinel.

The source repeatedly divides the parsed hexadecimal value by two to build a binary digit string, then parses that string as a base-10 integer. For example, `AC` becomes binary text `10101100`, and the function returns the decimal integer `10101100`. A leading minus sign is preserved. Zero is excluded because the pinned implementation builds an empty digit string for zero and then raises while parsing it. Malformed input returns `-9223372036854775808`; it cannot collide with a valid result. Four hex digits produce at most sixteen binary digits, so the largest result magnitude is `1111111111111111`, within signed 64-bit range.

| Language | Port |
|---|---|
| C | [`c/h/hex_to_bin.c`](../../../c/h/hex_to_bin.c) |
| C3 | [`c3/h/hex_to_bin.c3`](../../../c3/h/hex_to_bin.c3) |
| C++ | [`cpp/h/hex_to_bin.cpp`](../../../cpp/h/hex_to_bin.cpp) |
| Elisa | [`elisa/h/hex_to_bin.elisa`](../../../elisa/h/hex_to_bin.elisa) |
| Nim | [`nim/h/hex_to_bin.nim`](../../../nim/h/hex_to_bin.nim) |
| Odin | [`odin/h/hex_to_bin.odin`](../../../odin/h/hex_to_bin.odin) |
| Rust | [`rust/h/hex_to_bin.rs`](../../../rust/h/hex_to_bin.rs) |
| V | [`v/h/hex_to_bin.v`](../../../v/h/hex_to_bin.v) |
| Zig | [`zig/h/hex_to_bin.zig`](../../../zig/h/hex_to_bin.zig) |

Pinned source: [TheAlgorithms/Python `hex_to_bin.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/hex_to_bin.py). The source also accepts surrounding whitespace and Python's base-16 prefixes and separators; those textual forms are outside this fixed ASCII workload. See [`workload.json`](workload.json) for case and domain boundaries.
