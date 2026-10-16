# Gronsfeld cipher

Encrypt ASCII text with a repeating decimal-digit key, preserving letter case.

## Contract

- ABI: i64 array to byte output. Input is `[text bytes..., 0, key bytes...]`, where zero separates the text from the key.
- Text length is 0 through 256 bytes; text bytes are 1 through 127. The key has 1 through 64 bytes, each an ASCII digit.
- ASCII letters shift forward by the current key digit, wrapping within their original case. Other text bytes pass through unchanged and do not advance the key position.
- The source rejects an empty key even for empty text. Invalid input returns `-1`; insufficient output capacity returns `-2`. Errors leave the output unchanged.

## Source and workload

This package follows the pinned [TheAlgorithms/Rust implementation](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/gronsfeld.rs). The contract narrows text to ASCII, so the source's Unicode pass-through behavior is outside this workload. The distinction from the Python `gronsfeld_cipher` package is intentional: this Rust source preserves case and advances the key only for letters.

[`workload.json`](workload.json) covers case preservation, nonletter pass-through, key cycling, alphabet wraparound, empty text, malformed inputs, and insufficient output capacity. The independent source-shaped oracle is [`gronsfeld_oracle.py`](../../gronsfeld_oracle.py).

Verify the Rust implementation with `python3 benchmarks/verify_i64_array_bytes_output.py --algorithm gronsfeld --languages rust`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/gronsfeld.c`](../../../c/g/gronsfeld.c) |
| C3 | [`c3/g/gronsfeld.c3`](../../../c3/g/gronsfeld.c3) |
| C++ | [`cpp/g/gronsfeld.cpp`](../../../cpp/g/gronsfeld.cpp) |
| Elisa | [`elisa/g/gronsfeld.elisa`](../../../elisa/g/gronsfeld.elisa) |
| Nim | [`nim/g/gronsfeld.nim`](../../../nim/g/gronsfeld.nim) |
| Odin | [`odin/g/gronsfeld.odin`](../../../odin/g/gronsfeld.odin) |
| Rust | [`rust/g/gronsfeld.rs`](../../../rust/g/gronsfeld.rs) |
| V | [`v/g/gronsfeld.v`](../../../v/g/gronsfeld.v) |
| Zig | [`zig/g/gronsfeld.zig`](../../../zig/g/gronsfeld.zig) |
