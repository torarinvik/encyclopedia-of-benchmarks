# RSA Java BigInteger transform

This benchmark covers the pinned Java source's `BigInteger` overloads: encrypt one nonnegative integer with the public key, then decrypt the ciphertext with the private key. It does not benchmark the String overload, which encodes an entire message as one signed `BigInteger` byte array.

## Contract

The `i64_array_scalar` input is `[modulus, public_exponent, private_exponent, message_length, message_values...]`. The modulus is in `[128, 55295]`, each exponent is in `[1, 1000000]`, and the message contains 1 through 64 integer values in `[0, 127]`. Each message value is less than the modulus. The valid packed length is exactly `4 + message_length`, at most 68 values; the parser admits 69 values to reject an extra value at the maximum length.

For every input value `m`, call the Java `BigInteger` operations equivalent to `m.modPow(public_exponent, modulus)` and then `ciphertext.modPow(private_exponent, modulus)`. The contract does not validate that the supplied exponents form an RSA key pair; the workload uses `(n,e,d) = (323,5,173)`. The bounds keep all values small and make the benchmark independent of key size or `SecureRandom` behavior.

The signed 64-bit result is the low 63 bits of FNV-1a-64 over all ciphertexts, then all recovered integers, each encoded as a four-byte unsigned little-endian word. Invalid framing or out-of-range values return `-1`.

The cited class has only a random-key constructor, and `modulus`, `publicKey`, and `privateKey` are private fields. The adapter installs the fixed fields before the timed call and invokes the public `encrypt(BigInteger)` and `decrypt(BigInteger)` overloads. Constructor key generation and adapter state setup are excluded from measurement. The `encrypt(String)` and `decrypt(String)` overloads are outside this contract.

## Pinned source and workload

- TheAlgorithms/Java [`RSA.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/RSA.java) at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

[`workload.json`](workload.json) covers zero and high values, mixed input, the maximum message length, and malformed frames or key bounds. The independent oracle is [`rsa_java_big_integer_oracle.py`](../../rsa_java_big_integer_oracle.py).

## Implementations

| Language | Port |
| --- | --- |
| C | [rsa_java_big_integer.c](../../../c/r/rsa_java_big_integer.c) |
| C3 | [rsa_java_big_integer.c3](../../../c3/r/rsa_java_big_integer.c3) |
| C++ | [rsa_java_big_integer.cpp](../../../cpp/r/rsa_java_big_integer.cpp) |
| Elisa | [rsa_java_big_integer.elisa](../../../elisa/r/rsa_java_big_integer.elisa) |
| Nim | [rsa_java_big_integer.nim](../../../nim/r/rsa_java_big_integer.nim) |
| Odin | [rsa_java_big_integer.odin](../../../odin/r/rsa_java_big_integer.odin) |
| Rust | [rsa_java_big_integer.rs](../../../rust/r/rsa_java_big_integer.rs) |
| V | [rsa_java_big_integer.v](../../../v/r/rsa_java_big_integer.v) |
| Zig | [rsa_java_big_integer.zig](../../../zig/r/rsa_java_big_integer.zig) |
