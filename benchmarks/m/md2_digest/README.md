# MD2 digest

This benchmark computes the standard MD2 message digest of a bounded byte sequence. The source accepts bytes directly; the `float64_slice_io` ABI represents each byte as one exactly integral binary64 input value.

## Contract

- Input is a raw sequence of 0–63 bytes. Each input value must be an exact integer in `[0, 255]`; an empty sequence is valid and hashes the empty message. The ABI passes a null input pointer when the length is zero, so the adapter must treat that zero-length call as the empty byte sequence.
- Output is the 16 digest octets in order, each represented as a binary64 value in `[0, 255]`. Success returns `16`.
- Inputs with more than 63 elements, fractional or nonfinite values, or values outside the byte range return `-1`. A null output pointer or capacity below 16 returns `-2` without writing output.
- Output comparison uses zero absolute and relative tolerance because every output is an exact byte value.
- Each call starts from the initial MD2 state. The pinned C# implementation resets its internal state after returning the digest.

## Workload and oracle

[`workload.json`](workload.json) includes the empty-message and RFC 1319 examples, block-boundary messages, arbitrary binary bytes, a 63-byte maximum-length input, and malformed values and lengths. The independent [oracle](../../md2_digest_oracle.py) returns the digest bytes as numeric elements.

## Pinned source

The reference is [`Md2Digest.Digest`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Crypto/Digests/Md2Digest.cs) at commit `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c`. It applies MD2 padding and the 16-byte checksum before processing the message blocks and checksum block.
