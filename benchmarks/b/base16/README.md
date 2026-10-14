# Base16 codec

This benchmark encodes bytes as uppercase hexadecimal and decodes uppercase hexadecimal back to bytes. It shares a single mode-based input contract so both directions use the same byte-output ABI.

## Contract

- Input is `[mode, bytes...]`, with total length 1 through 65. Mode `0` encodes each payload value in 0 through 255 as two uppercase digits `0`-`9`, `A`-`F`; mode `1` decodes an even-length sequence of uppercase ASCII hex bytes.
- Empty payloads encode to and decode from an empty byte sequence. Lowercase, odd-length encoded input, invalid digits, invalid modes, and invalid lengths return `-1`.
- Insufficient output capacity returns `-2`. Ports use integer nibble arithmetic and no architecture-specific instructions.

## Workload and verification

[`workload.json`](workload.json) covers empty data, text, all byte ranges, invalid characters and lengths, and both directions. [`benchmarks/verify_base16.py`](../../verify_base16.py) checks all one-byte values, exhaustive two-byte inputs, deterministic longer payloads, capacity errors, and the recorded workload against Python's `bytes` and hexadecimal operations.

## Reviewed TheAlgorithms sources

- [Python `base16.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/base16.py) and [Rust `base16.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/base16.rs) both provide uppercase encoding and strict decoding. The benchmark normalizes their two separate functions into modes over a numeric byte array.
