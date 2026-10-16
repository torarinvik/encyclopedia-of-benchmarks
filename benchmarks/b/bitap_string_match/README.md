# Bitap String Match

This benchmark ports the pinned Python Bitap exact matcher, which uses one bit mask per lowercase letter to find the first pattern occurrence. The bounded contract uses a 64-bit state so every target language can express the same bit-parallel recurrence without machine-specific instructions.

## Contract

Input is a signed 64-bit array `[text_length, pattern_length, text bytes..., pattern bytes...]`. Text length is 0 to 4,096 bytes and pattern length is 0 to 63 bytes. All text and pattern bytes must be lowercase ASCII `a` through `z`, and the input length must match both declarations. The empty pattern returns 0. A nonempty pattern longer than the text, or one not found, returns -1. Malformed inputs return -2.

The matcher returns the zero-based index of the first exact match. The input and output contract avoid locale behavior and architecture-specific bit instructions.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm bitap_string_match --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/b/bitap_string_match/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bitap_string_match.c`](../../../c/b/bitap_string_match.c) |
| C3 | [`c3/b/bitap_string_match.c3`](../../../c3/b/bitap_string_match.c3) |
| C++ | [`cpp/b/bitap_string_match.cpp`](../../../cpp/b/bitap_string_match.cpp) |
| Elisa | [`elisa/b/bitap_string_match.elisa`](../../../elisa/b/bitap_string_match.elisa) |
| Nim | [`nim/b/bitap_string_match.nim`](../../../nim/b/bitap_string_match.nim) |
| Odin | [`odin/b/bitap_string_match.odin`](../../../odin/b/bitap_string_match.odin) |
| Rust | [`rust/b/bitap_string_match.rs`](../../../rust/b/bitap_string_match.rs) |
| V | [`v/b/bitap_string_match.v`](../../../v/b/bitap_string_match.v) |
| Zig | [`zig/b/bitap_string_match.zig`](../../../zig/b/bitap_string_match.zig) |

## Pinned source

- Python [`strings/bitap_string_match.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/bitap_string_match.py)
