# Caesar cipher

This benchmark applies a Caesar shift to an ASCII byte sequence. It rotates uppercase and lowercase English letters independently and copies every other ASCII byte unchanged.

## Contract

- Input is `[byte_0, ..., byte_n, shift]`. The final signed 64-bit value is the shift; preceding values are ASCII bytes from 0 through 127. A one-value input represents an empty message.
- Any signed 64-bit shift is accepted and normalized modulo 26. Negative shifts wrap backward through the alphabet.
- The result is the number of output bytes. Invalid input returns `-1`; insufficient output capacity returns `-2`. Errors leave the output buffer untouched.
- The benchmark uses a 7-bit ASCII contract so every language processes identical bytes and does not depend on a platform-specific text encoding.

## Workload and verification

[`workload.json`](workload.json) covers both letter cases, punctuation, control bytes, empty text, positive and negative shifts, modulo-equivalent shifts, signed 64-bit shift limits, invalid message bytes, and maximum input length. [`benchmarks/verify_caesar_cipher.py`](../../verify_caesar_cipher.py) checks all ASCII byte values across representative shifts, short exhaustive strings, seeded inputs, invalid values, and insufficient output capacity in all nine target languages.

## Reviewed TheAlgorithms sources

The candidate inventory links the pinned [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/ciphers/caesar_cipher.cpp), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Ciphers/CaesarCipher.js), [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Ciphers/CaesarCipher.php), and [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/caesar_cipher.py) `caesar_cipher` examples, plus [C# `CaesarEncoder`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Encoders/CaesarEncoder.cs), [Go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/cipher/caesar/caesar.go), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/Caesar.java), [Julia](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/cipher/caesar.jl), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/ciphers/caesar.rb), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/caesar.rs) `caesar` examples. The C# source has an `int` key and uses arithmetic that can overflow for large values; it matches this contract on ASCII letters for keys in `[-1,000,000, 1,000,000]`. The upstream files differ in accepted shifts, letter case, and treatment of nonletters; this benchmark uses one explicit contract for fair cross-language comparison.
