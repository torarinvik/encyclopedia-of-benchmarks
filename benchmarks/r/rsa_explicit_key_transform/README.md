# RSA explicit-key per-value transform (Go + Lua)

This benchmark compares the explicit-key, one-value-at-a-time RSA transform exposed by the pinned Go and Lua sources. It excludes their different key-generation routines and measures encrypting each supplied ASCII value, then decrypting each ciphertext.

## Contract

The `i64_array_scalar` input is `[modulus, public_exponent, private_exponent, message_length, message_values...]`. The modulus is in `[128, 55295]`, each exponent is in `[1, 1000000]`, and the message contains 1 through 64 ASCII values in `[0, 127]`. Each message value is less than the modulus. The valid packed length is exactly `4 + message_length`, at most 68 values; the parser admits 69 values to reject an extra value at the maximum length.

For each value `m`, compute `c = m^public_exponent mod modulus`, then recover `m' = c^private_exponent mod modulus`. The contract does not test whether the supplied exponents form a valid RSA key pair. The workload uses `(n,e,d) = (323,5,173)`. The bounds keep each modular multiplication exact in Lua's number representation, prevent overflow in the pinned Go helper, and keep every ciphertext below Go's UTF-16 surrogate range.

The signed 64-bit result is the low 63 bits of FNV-1a-64 over the ciphertexts in message order, each encoded as a four-byte unsigned little-endian word, followed by the recovered rune values in the same encoding. Invalid framing or out-of-range values return `-1`.

The Go adapter calls `Encrypt([]rune, publicExponent, modulus)` and `Decrypt([]rune, privateExponent, modulus)`; ASCII inputs and the ciphertext bound keep rune conversion lossless. The Lua adapter calls `cryption(modulus, exponent, value)` for each value. Lua's `generate_key_pair` and its prime/GCD helpers are outside the timed operation; the Go source accepts explicit exponents and modulus. Java's whole-message `BigInteger` overloads and Ruby's fixed-width decimal byte chunks have separate contracts.

## Pinned sources and workload

- TheAlgorithms/Go [`rsa.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/cipher/rsa/rsa.go) and [`exponentiation.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/modular/exponentiation.go), commit `5ba447ec5ff3d1213de65b92e726ee74c5d5cc19`.
- TheAlgorithms/Lua [`rsa.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/crypto/rsa.lua) and [`modpow.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/math/modpow.lua), commit `cedc141018ad48884318fe08a6db278664b17128`.

[`workload.json`](workload.json) covers zero and high ASCII values, mixed input, the maximum message length, and malformed frames or key bounds. The independent oracle is [`rsa_explicit_key_transform_oracle.py`](../../rsa_explicit_key_transform_oracle.py).

## Implementations

| Language | Port |
| --- | --- |
| C | [rsa_explicit_key_transform.c](../../../c/r/rsa_explicit_key_transform.c) |
| C3 | [rsa_explicit_key_transform.c3](../../../c3/r/rsa_explicit_key_transform.c3) |
| C++ | [rsa_explicit_key_transform.cpp](../../../cpp/r/rsa_explicit_key_transform.cpp) |
| Elisa | [rsa_explicit_key_transform.elisa](../../../elisa/r/rsa_explicit_key_transform.elisa) |
| Nim | [rsa_explicit_key_transform.nim](../../../nim/r/rsa_explicit_key_transform.nim) |
| Odin | [rsa_explicit_key_transform.odin](../../../odin/r/rsa_explicit_key_transform.odin) |
| Rust | [rsa_explicit_key_transform.rs](../../../rust/r/rsa_explicit_key_transform.rs) |
| V | [rsa_explicit_key_transform.v](../../../v/r/rsa_explicit_key_transform.v) |
| Zig | [rsa_explicit_key_transform.zig](../../../zig/r/rsa_explicit_key_transform.zig) |
