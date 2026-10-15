# Base64 alphabet to binary groups

This package ports the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/base64_to_binary.py). It maps each Base64 alphabet character independently to its six-bit value, in order. It does not decode byte-oriented Base64 padding. A leading minus sign is preserved before the resulting bits.

The `i64_array_bytes_output` ABI packs `[n, ascii[0..n]]`, with 0..256 ASCII bytes. Edge ASCII whitespace (tab, LF, VT, FF, CR, and space) is trimmed. After trimming, an optional leading `-` may precede zero or more Base64 alphabet characters (`A-Z`, `a-z`, `0-9`, `+`, `/`); the sign alone returns `-`, matching the source. Empty/all-whitespace inputs and invalid bytes return `-1`; insufficient output capacity returns `-2`; success returns the output byte count.

## Workload

[`workload.json`](workload.json) covers the upstream examples, alphabet boundaries, sign and whitespace handling, and invalid forms.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/base64_to_binary.c`](../../../c/b/base64_to_binary.c) |
| C3 | [`c3/b/base64_to_binary.c3`](../../../c3/b/base64_to_binary.c3) |
| C++ | [`cpp/b/base64_to_binary.cpp`](../../../cpp/b/base64_to_binary.cpp) |
| Elisa | [`elisa/b/base64_to_binary.elisa`](../../../elisa/b/base64_to_binary.elisa) |
| Nim | [`nim/b/base64_to_binary.nim`](../../../nim/b/base64_to_binary.nim) |
| Odin | [`odin/b/base64_to_binary.odin`](../../../odin/b/base64_to_binary.odin) |
| Rust | [`rust/b/base64_to_binary.rs`](../../../rust/b/base64_to_binary.rs) |
| V | [`v/b/base64_to_binary.v`](../../../v/b/base64_to_binary.v) |
| Zig | [`zig/b/base64_to_binary.zig`](../../../zig/b/base64_to_binary.zig) |
