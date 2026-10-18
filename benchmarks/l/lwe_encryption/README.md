# LWE encryption

This benchmark follows the pinned Java `LWEEncryption` constructor, message encryption, and decryption. The source's fixed toy parameters are `N=32`, `Q=3329`, `M=128`, and `B=3`. Random choices are supplied explicitly so every key and ciphertext is reproducible while the source's arithmetic, row order, and branches remain observable.

## Contract

The `i64_array_scalar` input is:

`[message_length, message_bytes..., s[32], A[128*32], error_draws[128], subset_bits...]`

`message_length` is 1 through 4, and each message byte is 0 through 255. The 32 secret entries and 4,096 matrix entries are `nextInt(3329)` results in `[0,3329)`. Matrix entries are row-major (`A[0][0]` through `A[127][31]`). The 128 error entries are raw `nextInt(7)` results in `[0,7)`; the source subtracts 3 to obtain errors in `[-3,3]`. The remaining values are `nextBoolean` results encoded as 0 or 1: exactly 128 subset choices per plaintext bit, ordered by message byte, most-significant bit first, then sample row 0 through 127. A valid packed length is exactly `4257 + 1025*message_length`; the maximum is 8,357 values. The parser admits 8,358 values to reject one extra value at the maximum message length.

Key generation consumes the secret first, then for each sample row consumes its 32 matrix entries followed by one error draw. It computes `b[i] = floorMod(sum(A[i][j] * s[j]) + error[i], 3329)`. Encryption processes each byte from most-significant bit to least-significant bit. For each bit it consumes that bit's 128 subset values, adds selected matrix rows into `u`, starts `v` at `bit * floor(3329/2)`, adds the selected `b` values, and reduces every result with nonnegative modulo 3329. Decryption computes `floorMod(v - dot(u,s), 3329)` and returns 1 exactly on `[832,2496)`. The source's fixed decryption bound check passes because `128*3 < floor(3329/4)`.

The scalar result is the low 63 bits of FNV-1a-64 over every ciphertext in message-bit order: each of its 32 `u` coefficients followed by `v`, with each value encoded as a two-byte unsigned little-endian integer. The recovered message bytes are appended as single bytes before finishing the fingerprint. Invalid framing, empty or over-bound messages, or values outside their specified ranges return `-1`. Null references cannot be represented by the packed input; the benchmark measures the generated ciphertext path and does not test the standalone `Ciphertext` constructor or copy-returning getters.

## Pinned source and workload

The source is TheAlgorithms/Java [`LWEEncryption.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/LWEEncryption.java) at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

[`workload.json`](workload.json) covers all-zero, all-one, mixed-bit, and maximum-length messages, along with malformed length and invalid secret, matrix, error, and subset values. The independent oracle is [`lwe_encryption_oracle.py`](../../lwe_encryption_oracle.py).

## Language ports

| Language | Source |
| --- | --- |
| C | [lwe_encryption.c](../../../c/l/lwe_encryption.c) |
| C3 | [lwe_encryption.c3](../../../c3/l/lwe_encryption.c3) |
| C++ | [lwe_encryption.cpp](../../../cpp/l/lwe_encryption.cpp) |
| Elisa | [lwe_encryption.elisa](../../../elisa/l/lwe_encryption.elisa) |
| Nim | [lwe_encryption.nim](../../../nim/l/lwe_encryption.nim) |
| Odin | [lwe_encryption.odin](../../../odin/l/lwe_encryption.odin) |
| Rust | [lwe_encryption.rs](../../../rust/l/lwe_encryption.rs) |
| V | [lwe_encryption.v](../../../v/l/lwe_encryption.v) |
| Zig | [lwe_encryption.zig](../../../zig/l/lwe_encryption.zig) |
