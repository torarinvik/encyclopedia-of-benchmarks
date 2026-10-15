# Binary string to Base64

This package ports the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/binary_to_base64.py). It maps each six-bit group of a binary string through the standard Base64 alphabet. It left-pads with zeroes to the next six-bit boundary and always adds one full group when the input length is already divisible by six. A leading minus sign is preserved before the encoded text.

The `i64_array_bytes_output` ABI packs `[n, ascii[0..n]]`. The benchmarked input has 1..256 ASCII bytes; edge ASCII whitespace (tab, LF, VT, FF, CR, and space) is trimmed. After trimming, an optional leading `-` is followed only by `0` and `1`; the sign alone is accepted and maps to `-A`, matching the source's empty post-sign loop. An all-whitespace input or any other byte is invalid. The output is ASCII; malformed input returns `-1`, insufficient output capacity returns `-2`, and success returns the output byte count.

This is distinct from byte-to-Base64 encoding: the input is a textual binary numeral, and the source's six-bit grouping and mandatory leading group are preserved.

## Workload

[`workload.json`](workload.json) covers the source examples, six-bit boundary behavior, sign and whitespace handling, empty/invalid forms, and the maximum input length.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binary_to_base64.c`](../../../c/b/binary_to_base64.c) |
| C3 | [`c3/b/binary_to_base64.c3`](../../../c3/b/binary_to_base64.c3) |
| C++ | [`cpp/b/binary_to_base64.cpp`](../../../cpp/b/binary_to_base64.cpp) |
| Elisa | [`elisa/b/binary_to_base64.elisa`](../../../elisa/b/binary_to_base64.elisa) |
| Nim | [`nim/b/binary_to_base64.nim`](../../../nim/b/binary_to_base64.nim) |
| Odin | [`odin/b/binary_to_base64.odin`](../../../odin/b/binary_to_base64.odin) |
| Rust | [`rust/b/binary_to_base64.rs`](../../../rust/b/binary_to_base64.rs) |
| V | [`v/b/binary_to_base64.v`](../../../v/b/binary_to_base64.v) |
| Zig | [`zig/b/binary_to_base64.zig`](../../../zig/b/binary_to_base64.zig) |
