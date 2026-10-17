# Pinned Salsa core variant (`salsa`)

This benchmark preserves the 16-word core from the pinned Rust `salsa20` function and labels it `salsa`. It copies the 16 input words, performs ten column/row double rounds, then adds the original words back with wrapping 32-bit arithmetic.

## Compatibility caveat

The pinned source's test vector agrees with the Wikipedia implementation linked in that source, but does not agree with Daniel J. Bernstein's original Salsa20 specification PDF. This benchmark intentionally reproduces the pinned source variant and must not be described as standards-conformant Salsa20.

## Contract

- The `i32_array_bytes_output` input is exactly 16 signed-i32 words. Each word is interpreted as its raw `u32` bit pattern, including negative signed values.
- The core applies ten double rounds in the source's exact column-round then row-round index order. Quarter-round rotations are 7, 9, 13, and 18 bits; additions and final feed-forward wrap modulo `2^32`.
- Output is the 16 resulting `u32` words, each serialized little-endian, for 64 bytes total. A valid call returns 64. A null input or malformed frame returns `-1`; null output or capacity below 64 returns `-2` without writing.

## Pinned test vector

Input words, in hexadecimal order:

`65787061 01020304 05060708 090a0b0c 0d0e0f10 6e642033 65666768 696a6b6c 6d6e6f70 71727374 322d6279 c9cacbcc cdcecfd0 d1d2d3d4 d5d6d7d8 7465206b`

The source test prints these output words in hexadecimal:

`de1d6f8d 91dbf69d 0db4b70c 8b4320d2 36694432 896d98b0 5aa7b76d 5738ca13 04e5a170 c8e479af 1542ed2f 30f26ba5 7da20203 cfe955c6 6f4cc7a0 6dd34359`

The workload stores the same words in the ABI's little-endian byte order.

Source: [Rust `salsa.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/salsa.rs).

Build and record with the `i32_array_bytes_output` ABI family.
