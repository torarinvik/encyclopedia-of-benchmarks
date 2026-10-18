# RSA Ruby byte chunks

This benchmark follows the pinned Ruby source's byte-oriented string cipher: encrypt every input byte independently, render each ciphertext as a zero-padded decimal chunk, concatenate the chunks, then split and decrypt them back to bytes.

## Contract

The `i64_array_scalar` input is `[modulus, public_exponent, private_exponent, message_length, byte_values...]`. The benchmark fixes `modulus` at 33, bounds each exponent to `[1, 7]`, and accepts 1 through 64 byte values in `[0, 32]`. The workload uses the valid small RSA tuple `(n,e,d) = (33,3,7)`. A two-digit chunk width follows from `n.to_s.size`; every ciphertext is less than 33 and fits that width. The valid packed length is exactly `4 + message_length`, at most 68 values; the parser admits 69 values to reject an extra value at the maximum length.

For each byte `m`, the cipher computes `(m**public_exponent) % modulus`, formats the result as a two-digit decimal chunk, and concatenates those chunks. The decipher parses each two-character chunk, computes `(chunk**private_exponent) % modulus`, and packs the recovered values as bytes. The exponent and byte bounds keep the source's unmodded integer powers within signed 64-bit range. The contract does not otherwise validate the key tuple.

The signed 64-bit result is the low 63 bits of FNV-1a-64 over the concatenated decimal ciphertext string's ASCII bytes, followed by the recovered bytes. Invalid framing or out-of-range values return `-1`.

The Ruby initializer accepts `n` and `e` but derives `d` from randomly generated primes. The adapter supplies `@n`, `@e`, and `@d` before the timed call, then follows the `cipher` and `decipher` method bodies. Key generation and adapter setup are excluded. The source calls its interactive `main` unconditionally, so the adapter extracts the source method bodies and omits only the final `main` invocation; it does not load or invoke that command-line entry point.

## Pinned source and workload

- TheAlgorithms/Ruby [`rsa.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/ciphers/rsa.rb) at commit `bda11bdfd83b7958e1ca98247e5e43100ca88865`.

[`workload.json`](workload.json) covers zero and high in-range bytes, mixed input, the maximum message length, and malformed frames or key bounds. The independent oracle is [`rsa_ruby_byte_chunk_oracle.py`](../../rsa_ruby_byte_chunk_oracle.py).

## Implementations

| Language | Port |
| --- | --- |
| C | [rsa_ruby_byte_chunk.c](../../../c/r/rsa_ruby_byte_chunk.c) |
| C3 | [rsa_ruby_byte_chunk.c3](../../../c3/r/rsa_ruby_byte_chunk.c3) |
| C++ | [rsa_ruby_byte_chunk.cpp](../../../cpp/r/rsa_ruby_byte_chunk.cpp) |
| Elisa | [rsa_ruby_byte_chunk.elisa](../../../elisa/r/rsa_ruby_byte_chunk.elisa) |
| Nim | [rsa_ruby_byte_chunk.nim](../../../nim/r/rsa_ruby_byte_chunk.nim) |
| Odin | [rsa_ruby_byte_chunk.odin](../../../odin/r/rsa_ruby_byte_chunk.odin) |
| Rust | [rsa_ruby_byte_chunk.rs](../../../rust/r/rsa_ruby_byte_chunk.rs) |
| V | [rsa_ruby_byte_chunk.v](../../../v/r/rsa_ruby_byte_chunk.v) |
| Zig | [rsa_ruby_byte_chunk.zig](../../../zig/r/rsa_ruby_byte_chunk.zig) |
