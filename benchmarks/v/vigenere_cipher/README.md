# Vigenère cipher

This benchmark encrypts 7-bit ASCII text with a repeating alphabetic key. The key advances only when the message contains an English letter; encryption preserves the message letter's case and copies other ASCII bytes unchanged.

## Contract

- Input is `[message bytes..., 0, key bytes...]`, where the zero separates message from key. The total input length is 2 through 66, the key is nonempty and contains only ASCII `A-Z` or `a-z`, and message bytes are in `1..127`.
- The key is case-insensitive. Uppercase and lowercase message letters are shifted by the key letter's position (`A/a = 0`); nonletters do not consume a key character.
- The result is the number of encrypted message bytes. Invalid input returns `-1`; insufficient output capacity returns `-2`. Errors leave the output buffer untouched.
- Upstream versions differ on case handling, empty keys, key filtering, and whether nonletters advance the key. This contract makes those choices explicit for cross-language comparison.

## Workload and verification

[`workload.json`](workload.json) includes the classic `ATTACKATDAWN` / `LEMON` vector, mixed case and punctuation, empty text, key cycling, control bytes, invalid keys, and maximum input length. [`benchmarks/verify_vigenere_cipher.py`](../../verify_vigenere_cipher.py) checks exhaustive short inputs, deterministic text/key pairs, invalid inputs, and insufficient output capacity in all nine target languages.

## Reviewed TheAlgorithms sources

The canonical `vigenere_cipher` candidate includes [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/ciphers/vigenere_cipher.cpp), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Ciphers/VigenereCipher.js), and [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/vigenere_cipher.py). The `vigenere` filename is also used by [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/Vigenere.java), [Julia](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/cipher/vigenere.jl), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/vigenere.rs); [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Ciphers/VignereCipher.php) uses the misspelled filename `vignere_cipher` for the same cipher.
