# Split

This package compares the pinned Python exact-separator scan and F# character-separator scan on the shared domain where their outputs agree. Python accepts multi-character separators, supports an empty separator by returning the original string as one field, and retains a trailing empty field; F# accepts one character, returns `[""]` for nonempty strings without a separator, and omits a trailing empty field. The benchmark restricts the separator to one ASCII byte, requires every nonempty text to contain the separator, and excludes text ending in the separator.

## Contract

Input is a signed 64-bit array `[text_byte_length, separator_byte, ASCII text bytes...]`. Text length is 0 through 256, the separator and text bytes are 0 through 127, and the exact input length is `2 + text_byte_length`. Empty text yields one empty field. Scanning is left-to-right with non-overlapping separator matches; empty fields from leading or adjacent separators are preserved. Nonempty text must contain the separator and may not end with it.

Output bytes are `[field_count:u16 little-endian, repeated [field_byte_length:u16 little-endian, field bytes]]`. This preserves empty fields and arbitrary ASCII byte content, including NUL. Maximum output capacity is 515 bytes. Input validation precedes output-buffer checks: invalid input returns `-1`; otherwise a null or undersized output buffer returns `-2` without writing.

The independent [oracle](../../split_oracle.py) and [`workload.json`](workload.json) include source examples, boundary bytes, empty and adjacent fields, malformed framing, and output-capacity cases.

## Pinned sources

- [TheAlgorithms/Python `strings/split.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/split.py)
- [TheAlgorithms/F-Sharp `Algorithms/Strings/Split.fs`](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/Split.fs)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/split.c`](../../../c/s/split.c) |
| C3 | [`c3/s/split.c3`](../../../c3/s/split.c3) |
| C++ | [`cpp/s/split.cpp`](../../../cpp/s/split.cpp) |
| Elisa | [`elisa/s/split.elisa`](../../../elisa/s/split.elisa) |
| Nim | [`nim/s/split.nim`](../../../nim/s/split.nim) |
| Odin | [`odin/s/split.odin`](../../../odin/s/split.odin) |
| Rust | [`rust/s/split.rs`](../../../rust/s/split.rs) |
| V | [`v/s/split.v`](../../../v/s/split.v) |
| Zig | [`zig/s/split.zig`](../../../zig/s/split.zig) |
