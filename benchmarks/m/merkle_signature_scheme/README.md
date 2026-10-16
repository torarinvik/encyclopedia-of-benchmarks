# Merkle Signature Scheme Verification

This package benchmarks verification in the pinned [TheAlgorithms/Java `MerkleSignatureScheme`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/MerkleSignatureScheme.java), using the pinned `WinternitzSignature` helper for WOTS verification semantics. Key generation, random signing, and signing-time randomness are excluded.

The packed input is `[height,w,message_len,message_bytes...,leaf_index,wots_signature[32*L],wots_public_key[32*L],auth_path[32*height],root[32]]`. Heights are 2..10, `w` is 4, 16, or 256, and the corresponding WOTS lengths are 133, 67, and 34. Messages contain 0..64 ASCII bytes. Signature, public-key, authentication-path, and root bytes may use the full 0..255 range. The verifier hashes the message, derives Winternitz message/checksum digits, advances each signature chain, hashes the concatenated WOTS public key as the leaf, and folds siblings left or right according to the leaf index bits.

The output is one little-endian signed i64 boolean (`0` or `1`), so the output buffer is 8 bytes and successful calls return 8. Malformed input returns `-1`; insufficient capacity returns `-2`. Work is O(L × w × 32 + height × 32) SHA-256 work; auxiliary space is O(L × 32).

See [`workload.json`](workload.json) and the independent [`merkle_signature_scheme_oracle.py`](../../merkle_signature_scheme_oracle.py).

## Language ports

- C: [`c/m/merkle_signature_scheme.c`](../../../c/m/merkle_signature_scheme.c)
- C3: [`c3/m/merkle_signature_scheme.c3`](../../../c3/m/merkle_signature_scheme.c3)
- C++: [`cpp/m/merkle_signature_scheme.cpp`](../../../cpp/m/merkle_signature_scheme.cpp)
- Elisa: [`elisa/m/merkle_signature_scheme.elisa`](../../../elisa/m/merkle_signature_scheme.elisa)
- Nim: [`nim/m/merkle_signature_scheme.nim`](../../../nim/m/merkle_signature_scheme.nim)
- Odin: [`odin/m/merkle_signature_scheme.odin`](../../../odin/m/merkle_signature_scheme.odin)
- Rust: [`rust/m/merkle_signature_scheme.rs`](../../../rust/m/merkle_signature_scheme.rs)
- V: [`v/m/merkle_signature_scheme.v`](../../../v/m/merkle_signature_scheme.v)
- Zig: [`zig/m/merkle_signature_scheme.zig`](../../../zig/m/merkle_signature_scheme.zig)
