# Atbash cipher

This benchmark applies the Atbash substitution to a 7-bit ASCII byte sequence. Uppercase and lowercase English letters map to the corresponding reversed letter in the same case; all other bytes pass through unchanged.

## Contract

- Input is a sequence of 0 through 66 signed 64-bit values in the range `0..127`.
- The mapping is `A ↔ Z`, `B ↔ Y`, ..., `a ↔ z`; bytes outside the two letter ranges remain unchanged. Atbash is its own inverse.
- The result is the number of output bytes. Invalid input returns `-1`; insufficient output capacity returns `-2`. Errors leave the output buffer untouched.
- The benchmark defines ASCII byte values explicitly, so behavior does not depend on the host character set.

## Workload and verification

[`workload.json`](workload.json) covers empty input, both alphabets, mixed case, punctuation, digits, control bytes, and maximum length. [`benchmarks/verify_atbash_cipher.py`](../../verify_atbash_cipher.py) checks every one-byte and two-byte ASCII sequence, seeded longer inputs, invalid values, and insufficient output capacity in all nine target languages.
The generic byte-output verifier also checks this benchmark with an independent oracle: `python3 benchmarks/verify_i64_array_bytes_output.py --algorithm atbash_cipher`.

## Reviewed TheAlgorithms sources

The `atbash_cipher` candidate links [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/ciphers/atbash_cipher.cpp), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/AtbashCipher.java), and [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Ciphers/AtbashCipher.php). The [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Ciphers/Atbash.js), [Julia](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/cipher/atbash.jl), and [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/atbash.py) sources use the filename `atbash`. Their punctuation and letter-case behavior differs; the benchmark follows the explicit case-preserving ASCII contract above.
