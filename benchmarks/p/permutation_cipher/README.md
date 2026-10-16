# Permutation cipher

## Contract

The input is `[text_length, ASCII bytes..., key_length, one-based permutation positions...]`. Text length is 0–64 and key length is 1–8. The key must be a permutation of `1..=key_length`. Inputs outside these bounds or malformed arrays return `-1`.

The benchmark follows the pinned Java encryption method: it removes ASCII whitespace, uppercases ASCII lowercase letters, pads the cleaned text with `X` until its length is a multiple of the key length, and rearranges each block so output position `i` receives input position `key[i]-1`. To keep the variable-length ciphertext observable through the scalar ABI, the result is its polynomial hash modulo 1,000,000,007, calculated from zero using `h = (257*h + byte) mod 1,000,000,007`.

The Python source has a distinct contract: it chooses a random key when one is omitted, uses zero-based keys when provided, does not pad partial blocks, and preserves whitespace. Those behaviors are not part of this deterministic Java-based benchmark. The bounded contract is ASCII-only; Java's broader Unicode uppercasing and whitespace behavior is excluded.

## Source review

The Java `encrypt` method validates that the key contains each one-based position exactly once, returns empty text unchanged, strips whitespace, uppercases, pads with `X`, and applies the key ordering per block. The Python `encrypt` method instead uses random defaults and zero-based key positions. The benchmark supplies a fixed key and records the Java semantics.

Pinned sources: [Java `PermutationCipher.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/PermutationCipher.java) and [Python `permutation_cipher.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/permutation_cipher.py).

## Workload and implementations

[`workload.json`](workload.json) includes padding, permutation order, case folding, whitespace removal, the empty string, and a key that leaves trailing `X` characters intact. The [runtime oracle](../../permutation_cipher_oracle.py) applies the contract above.

| Language | Port |
|---|---|
| C | [`c/p/permutation_cipher.c`](../../../c/p/permutation_cipher.c) |
| C3 | [`c3/p/permutation_cipher.c3`](../../../c3/p/permutation_cipher.c3) |
| C++ | [`cpp/p/permutation_cipher.cpp`](../../../cpp/p/permutation_cipher.cpp) |
| Elisa | [`elisa/p/permutation_cipher.elisa`](../../../elisa/p/permutation_cipher.elisa) |
| Nim | [`nim/p/permutation_cipher.nim`](../../../nim/p/permutation_cipher.nim) |
| Odin | [`odin/p/permutation_cipher.odin`](../../../odin/p/permutation_cipher.odin) |
| Rust | [`rust/p/permutation_cipher.rs`](../../../rust/p/permutation_cipher.rs) |
| V | [`v/p/permutation_cipher.v`](../../../v/p/permutation_cipher.v) |
| Zig | [`zig/p/permutation_cipher.zig`](../../../zig/p/permutation_cipher.zig) |
