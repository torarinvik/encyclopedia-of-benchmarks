# Java `my_atoi`

This benchmark ports the pinned Java parser with a bounded byte-array adapter. It keeps Java's `String.trim()` behavior, optional sign, decimal-prefix parsing, and signed 32-bit saturation while making the input deterministic across languages.

## Contract

- Input is an array of 0 through 256 signed 64-bit slots. Every non-null slot must be an ASCII byte value from 0 through 127.
- A null input pointer returns 0 before checking its declared length. A non-null empty array also returns 0.
- Trim all leading and trailing bytes at or below `0x20`, matching Java `String.trim()` for this ASCII-only domain. Then consume one optional `+` or `-` and the longest initial run of ASCII decimal digits. Stop at the first other byte; return 0 if no digits are present.
- Saturate parsed values to the signed 32-bit range. Invalid non-null lengths or byte values return `INT64_MIN`, which cannot collide with any valid parsed value.
- The function returns the parsed scalar directly.

[`workload.json`](workload.json) covers null and empty inputs, NUL/control trimming, prefix termination, signed limits and overflow, maximum valid length, and invalid lengths/bytes. The independent oracle is [`my_atoi_oracle.py`](../../my_atoi_oracle.py).

## Pinned source

The pinned Java implementation is [`MyAtoi.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/MyAtoi.java). It returns zero for null or empty strings, applies `String.trim()`, accepts an optional sign and ASCII digits, stops at the first non-digit, and saturates to signed 32-bit bounds. This remains distinct from the local C `c_atoi_str_to_integer`: Java trims leading NUL/control bytes, while the C parser stops at NUL and skips only six ASCII whitespace bytes.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/my_atoi.c`](../../../c/m/my_atoi.c) |
| C3 | [`c3/m/my_atoi.c3`](../../../c3/m/my_atoi.c3) |
| C++ | [`cpp/m/my_atoi.cpp`](../../../cpp/m/my_atoi.cpp) |
| Elisa | [`elisa/m/my_atoi.elisa`](../../../elisa/m/my_atoi.elisa) |
| Nim | [`nim/m/my_atoi.nim`](../../../nim/m/my_atoi.nim) |
| Odin | [`odin/m/my_atoi.odin`](../../../odin/m/my_atoi.odin) |
| Rust | [`rust/m/my_atoi.rs`](../../../rust/m/my_atoi.rs) |
| V | [`v/m/my_atoi.v`](../../../v/m/my_atoi.v) |
| Zig | [`zig/m/my_atoi.zig`](../../../zig/m/my_atoi.zig) |
