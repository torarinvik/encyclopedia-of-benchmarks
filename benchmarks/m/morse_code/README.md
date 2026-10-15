# Morse Code Encoder

This benchmark encodes ASCII letters and digits as International Morse. The pinned candidates come from C++ (two snapshots), JavaScript, PHP, Python, and Rust. Their APIs differ: the C++ versions accept lowercase letters and digits and append a trailing separator; JavaScript accepts mixed-case text, punctuation, and custom symbols, using `*` as its default dot; PHP, Python, and Rust also handle spaces and punctuation, with different invalid-character behavior.

## Contract

- Input is an array of 0 through 682 signed 64-bit values, each representing one ASCII byte.
- Valid input bytes are `A`–`Z`, `a`–`z`, and `0`–`9`. ASCII letters are case-insensitive; output is normalized to canonical `.` and `-` Morse.
- Encoded character codes are separated by one ASCII space, with no leading or trailing space. Input spaces, punctuation, non-ASCII values, and input longer than 682 return `-1`.
- Empty input returns an empty output. The function returns the output byte length. Insufficient output capacity returns `-2` without writing output.
- A maximum-length input has at most 4,091 output bytes, within the byte-output ABI bounds.

All nine implementations use the same numeric Morse-code table and portable integer operations. They do not require processor-specific instructions. The input and output buffers use the shared `i64_array_bytes_output` ABI.

## Workload and verification

[`workload.json`](workload.json) covers empty and singleton input, case folding, every digit, the full alphabet, invalid values, deterministic random text, and the maximum input length. [`benchmarks/verify_morse_code.py`](../../verify_morse_code.py) uses a separate dictionary oracle, checks 4,490 input arrays per language, verifies invalid-input and zero-capacity statuses, and checks every published recorder result.

## Upstream sources

- [TheAlgorithms/C-Plus-Plus](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/ciphers/morse_code.cpp)
- [TheAlgorithms/C-Plus-Plus-1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/ciphers/morse_code.cpp)
- [TheAlgorithms/JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Ciphers/MorseCode.js)
- [TheAlgorithms/PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Ciphers/MorseCode.php)
- [TheAlgorithms/Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/morse_code.py)
- [TheAlgorithms/Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/morse_code.rs)
