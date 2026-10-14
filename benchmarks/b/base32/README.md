# Base32 codec

This benchmark encodes arbitrary bytes as uppercase Base32 and decodes that representation back to bytes. It uses one mode-based byte-array contract for both directions.

## Contract

- Input is `[mode, values...]`, with total length 1 through 66. Mode `0` encodes byte values 0 through 255. Mode `1` decodes uppercase ASCII from `A` through `Z` and `2` through `7`.
- Encoding uses the RFC 4648 alphabet and `=` padding to a multiple of eight characters. Decoding accepts either canonical padding or a valid unpadded form. It rejects invalid symbols, illegal symbol counts, misplaced or incorrect padding, and nonzero unused trailing bits.
- Empty input encodes to and decodes from empty output. Invalid input returns `-1`; insufficient output capacity returns `-2`. All nine implementations use portable integer bit operations.

## Workload and verification

[`workload.json`](workload.json) covers the RFC 4648 text vectors, binary payloads, padded and unpadded decoding, malformed encodings, and maximum input lengths. [`benchmarks/verify_base32.py`](../../verify_base32.py) checks every single byte and all 65,536 two-byte payloads in both directions, deterministic longer payloads, capacity errors, and the recorded workload.

## Reviewed TheAlgorithms sources

- [Python `base32.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/base32.py) and [Rust `base32.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/base32.rs) provide the discovery references. The Rust implementation is byte-oriented and documents padded and unpadded input. The benchmark normalizes both sources to the same strict RFC 4648 byte contract across the target languages.
