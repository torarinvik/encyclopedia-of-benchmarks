# Base64 codec

This benchmark encodes arbitrary bytes as RFC 4648 Base64 and decodes that representation back to bytes. A mode-based array contract lets both operations share the byte-output benchmark interface.

## Contract

- Input is `[mode, values...]`, with total length 1 through 66. Mode `0` encodes byte values 0 through 255. Mode `1` decodes Base64 ASCII using the standard alphabet `A-Z`, `a-z`, `0-9`, `+`, and `/`.
- Encoding pads output with `=` to a multiple of four characters. Decoding accepts canonical padding or a valid unpadded form. It rejects invalid symbols, illegal symbol counts, misplaced or incorrect padding, and nonzero unused trailing bits.
- Empty input encodes to and decodes from empty output. Invalid input returns `-1`; insufficient output capacity returns `-2`. Every implementation uses portable integer bit operations.

## Workload and verification

[`workload.json`](workload.json) includes the RFC 4648 text vectors, binary payloads, padded and unpadded decoding, malformed encodings, and maximum input lengths. [`benchmarks/verify_base64.py`](../../verify_base64.py) checks every single-byte and two-byte payload in both directions, deterministic longer payloads, capacity errors, and the recorded workload.

## Reviewed TheAlgorithms sources

- [Go `base64.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/conversion/base64.go), [Java `Base64.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/Base64.java), and [Rust `base64.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/base64.rs) provide the discovery references. The benchmark normalizes their byte-oriented encoders and decoders to a shared strict RFC 4648 contract across all target languages.
