# Lempel–Ziv–Welch (LZW)

This package ports the pinned Java LZW compressor and decompressor for bounded ASCII input. The compressor uses the source's initial dictionary of all 256 single-byte characters and adds phrases in encounter order. The decompressor accepts the source code stream, including the `code == next_dictionary_code` special case. The Java method removes its first code from the supplied list; these ports instead read the benchmark input without modifying its buffer.

## Contract

- The `i64_array_scalar` input is `[mode, n, payload_0, ..., payload_(n-1)]`, with exact length `n + 2` and `0 <= n <= 4096`.
- `mode == 0` compresses `n` ASCII byte values in `0..127`. Empty input compresses to an empty code stream.
- `mode == 1` decompresses `n` LZW codes in `0..4351`. Empty input decompresses to an empty byte stream. A nonempty code sequence must decode successfully and every decoded byte must be ASCII (`0..127`). The decoded output is limited to 65,536 bytes.
- Invalid mode, malformed length, out-of-range input values, an invalid code stream, a non-ASCII decoded byte, or a decoded output longer than 65,536 bytes returns `-1`. Decoding stops before appending a phrase that would exceed the output bound.
- The scalar result is the low 63 bits of FNV-1a-64 over the signed-i64 little-endian words `[mode, result_length, result_values...]`. For compression, result values are the emitted codes; for decompression, they are decoded ASCII bytes. The offset basis is `14695981039346656037` and the prime is `1099511628211`.

The [independent oracle](../../lzw_oracle.py) uses byte-string dictionary entries rather than the prefix/suffix representation used by the language ports. The [workload](workload.json) covers empty streams, the canonical LZW phrase, repeated-character and binary-safe ASCII input, the KwKwK decoder case, maximum-size input, invalid codes, and the output-length boundary.

## Upstream source

- [TheAlgorithms/Java `LZW.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/compression/LZW.java)

| Language | Port |
|---|---|
| C | [`c/l/lzw.c`](../../../c/l/lzw.c) |
| C3 | [`c3/l/lzw.c3`](../../../c3/l/lzw.c3) |
| C++ | [`cpp/l/lzw.cpp`](../../../cpp/l/lzw.cpp) |
| Elisa | [`elisa/l/lzw.elisa`](../../../elisa/l/lzw.elisa) |
| Nim | [`nim/l/lzw.nim`](../../../nim/l/lzw.nim) |
| Odin | [`odin/l/lzw.odin`](../../../odin/l/lzw.odin) |
| Rust | [`rust/l/lzw.rs`](../../../rust/l/lzw.rs) |
| V | [`v/l/lzw.v`](../../../v/l/lzw.v) |
| Zig | [`zig/l/lzw.zig`](../../../zig/l/lzw.zig) |
