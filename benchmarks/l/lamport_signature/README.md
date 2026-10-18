# Lamport one-time signature

This benchmark follows the pinned Java `LamportSignature` key generation, signing, and verification behavior. The only injected behavior is key randomness: each call receives the exact 512 random 32-byte blocks that the source would request from `SecureRandom`, in source order. This makes the operation reproducible while preserving the source's key layout, SHA-256 use, and digest-bit selection.

## Contract

The `i64_array_scalar` input is
`[message_length, message_bytes..., verify_message_length, verify_message_bytes..., tamper_index, sign_twice, entropy_bytes...]`.
Both message lengths are 0 through 64, message values and entropy values are bytes in 0 through 255, and the entropy suffix contains exactly 16,384 bytes. A valid call has exactly `4 + message_length + verify_message_length + 16,384` i64 values (maximum 16,516); one extra value is parseable only to report malformed framing. `tamper_index` is `-1` for an unmodified signature or a byte index from 0 through 8,191. `sign_twice` is 0 or 1.

Generate the key pair from 512 consecutive entropy blocks: 32 bytes for each `(bit, value)` pair, with bit positions 0 through 255 and values 0 then 1. The public key entry for each secret is its SHA-256 digest. Hash the message with SHA-256. For each digest bit in index order, most-significant bit first within each digest byte, append the corresponding 32-byte private secret. The result is the source's 8,192-byte signature.

Verify the signature against `verify_message`. If `tamper_index` is nonnegative, flip bit 0 of that byte in a copy before verification. For each bit position, hash the revealed 32-byte value and compare it with the public-key digest selected by the verification message's corresponding SHA-256 bit; stop at the first mismatch. A `sign_twice` value of 1 attempts a second signature with the same key pair and maps the source's one-time-use exception to `-1`.

Success returns the low 63 bits of FNV-1a-64 over the public key bytes in `(bit, value, byte)` order, the original unmodified signature bytes, and one final byte (`1` if verification succeeds, otherwise `0`). The fingerprint uses the standard 64-bit FNV offset basis and prime, wrapping after each byte. Malformed framing, invalid lengths or byte values, an out-of-range mutation index, or the repeated-sign attempt returns `-1`.

The packed input cannot represent Java `null` references, and this contract does not benchmark exception text or the mutable-array getters. The one-time signing rule remains observable through `sign_twice`.

## Workload

[`workload.json`](workload.json) covers empty and nonempty messages, MSB-first digest-bit selection, successful verification, verification against a different message, signature tampering, second-sign rejection, malformed framing, and input bounds. It uses fixed supplied entropy bytes; it does not call or benchmark a random-number generator.

## Pinned source

- TheAlgorithms/Java [`LamportSignature.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/LamportSignature.java), including `generateKeyPair`, `KeyPair.sign`, and `KeyPair.verify`.

## Language ports

| Language | Source |
| --- | --- |
| C | [lamport_signature.c](../../../c/l/lamport_signature.c) |
| C3 | [lamport_signature.c3](../../../c3/l/lamport_signature.c3) |
| C++ | [lamport_signature.cpp](../../../cpp/l/lamport_signature.cpp) |
| Elisa | [lamport_signature.elisa](../../../elisa/l/lamport_signature.elisa) |
| Nim | [lamport_signature.nim](../../../nim/l/lamport_signature.nim) |
| Odin | [lamport_signature.odin](../../../odin/l/lamport_signature.odin) |
| Rust | [lamport_signature.rs](../../../rust/l/lamport_signature.rs) |
| V | [lamport_signature.v](../../../v/l/lamport_signature.v) |
| Zig | [lamport_signature.zig](../../../zig/l/lamport_signature.zig) |
