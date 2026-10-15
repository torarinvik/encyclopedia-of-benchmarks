# XOR cipher

This benchmark XORs each message byte with the corresponding byte in a repeating key. Applying the same key a second time restores the original bytes.

## Contract

- Input is `[message_length, key_length, message_bytes..., key_bytes...]`. The total array length is 3 through 66, message length is 0 through 63, and key length is 1 through 63. Both message and key bytes are in `0..255`.
- The key repeats cyclically over the message. An empty message is valid when the key is nonempty.
- The result is the number of output bytes. Invalid input returns `-1`; insufficient output capacity returns `-2`. Errors leave the output buffer untouched.
- The benchmark returns raw bytes so the result can include zero and non-ASCII bytes. Upstream candidates vary between an integer key, a repeating text key, and hexadecimal output; this contract normalizes them to one byte-oriented XOR operation.

## Workload and verification

[`workload.json`](workload.json) covers empty input, single-byte and repeating keys, zero and high bytes, invalid lengths and values, and maximum message length. [`benchmarks/verify_xor_cipher.py`](../../verify_xor_cipher.py) checks all message byte values with representative keys, exhaustive short byte patterns, seeded message/key arrays, invalid inputs, and insufficient output capacity in all nine target languages.

## Reviewed TheAlgorithms sources

The `xor_cipher` filename appears in [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/ciphers/xor_cipher.cpp), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/xor_cipher.py), and [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/ciphers/xor_cipher.ts). Java, JavaScript, and PHP use the spelling `xorcipher`: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/XORCipher.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Ciphers/XORCipher.js), and [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Ciphers/XORCipher.php).
