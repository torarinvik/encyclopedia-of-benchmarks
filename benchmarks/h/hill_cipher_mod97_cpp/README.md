# Hill cipher (modulus 97, C++)

This package ports the pinned C++ Hill cipher over its 97-character literal ASCII alphabet. The encrypt key is `[[2, 5], [1, 6]]`; its determinant is 7, which is invertible modulo 97. The fixed decrypt matrix is `[[84, 27], [83, 28]]`, the modular inverse. Fixing the key keeps the benchmark deterministic and measures the block transform.

Pinned source: [TheAlgorithms/C-Plus-Plus `hill_cipher.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/ciphers/hill_cipher.cpp) and [TheAlgorithms/C-Plus-Plus-1 `hill_cipher.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/ciphers/hill_cipher.cpp). The pinned implementations have the same alphabet and block behavior.

## Contract

Input is signed 64-bit slots `[operation, raw_length, ASCII bytes...]`. Operation 0 encrypts and 1 decrypts. `raw_length` is 1 through 256. Payload bytes must be members of the source alphabet, in its exact order:

The alphabet order is uppercase letters, lowercase letters, digits, then `~!@#$%^&*()_+`, a backtick, hyphen, equals sign, square brackets, braces, vertical bar, semicolon, apostrophe, double quote, colon, comma, period, slash, angle brackets, question mark, backslash, carriage return, line feed, and space.

Characters are processed literally, preserving case. The source pads an odd-length message with NUL to complete the final two-byte block. NUL is the alphabet's terminator, and its lookup index is 97, so its modular value is 0. The output includes both bytes of that padded block; decryption does not remove it.

Each pair is a column vector `[a,b]` of alphabet indices. Encryption applies `[[2,5],[1,6]]` modulo 97; decryption applies `[[84,27],[83,28]]`. The result is encoded with the same alphabet. The function returns the output byte count, `-1` for malformed or unsupported input, and `-2` for null or insufficient output capacity.

`workload.json` covers source-style encryption and decryption, punctuation, mixed case, CR/LF and spaces, odd-length NUL padding, the full alphabet, the 256-byte bound, malformed inputs, and insufficient output capacity.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm hill_cipher_mod97_cpp --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/h/hill_cipher_mod97_cpp/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/hill_cipher_mod97_cpp.c`](../../../c/h/hill_cipher_mod97_cpp.c) |
| C3 | [`c3/h/hill_cipher_mod97_cpp.c3`](../../../c3/h/hill_cipher_mod97_cpp.c3) |
| C++ | [`cpp/h/hill_cipher_mod97_cpp.cpp`](../../../cpp/h/hill_cipher_mod97_cpp.cpp) |
| Elisa | [`elisa/h/hill_cipher_mod97_cpp.elisa`](../../../elisa/h/hill_cipher_mod97_cpp.elisa) |
| Nim | [`nim/h/hill_cipher_mod97_cpp.nim`](../../../nim/h/hill_cipher_mod97_cpp.nim) |
| Odin | [`odin/h/hill_cipher_mod97_cpp.odin`](../../../odin/h/hill_cipher_mod97_cpp.odin) |
| Rust | [`rust/h/hill_cipher_mod97_cpp.rs`](../../../rust/h/hill_cipher_mod97_cpp.rs) |
| V | [`v/h/hill_cipher_mod97_cpp.v`](../../../v/h/hill_cipher_mod97_cpp.v) |
| Zig | [`zig/h/hill_cipher_mod97_cpp.zig`](../../../zig/h/hill_cipher_mod97_cpp.zig) |
