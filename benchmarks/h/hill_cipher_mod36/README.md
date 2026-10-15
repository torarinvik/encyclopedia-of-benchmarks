# Hill cipher (modulus 36)

Encrypt or decrypt ASCII text with the pinned Python modulus-36 Hill cipher and the equivalent Rust implementation. The alphabet order is `ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789`. The package uses the fixed 2×2 key `[[2, 5], [1, 6]]`; its determinant is 7, which is coprime with 36, and its modular inverse is `[[6, 25], [5, 26]]`.

Python source: [TheAlgorithms/Python `hill_cipher.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/hill_cipher.py). The Rust source is [TheAlgorithms/Rust `hill_cipher.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/hill_cipher.rs). The Rust source uses the repository-wide pinned commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`.

## Contract

Input is signed 64-bit slots `[operation, raw_length, ASCII bytes...]`, where operation 0 encrypts and 1 decrypts, and `raw_length` is 1 through 256. Every byte must be ASCII. Processing uppercases ASCII lowercase letters, filters out everything except `A-Z` and `0-9`, then repeats the final retained symbol until the filtered length is divisible by two. At least one alphanumeric character must remain; this avoids Python's empty-filter indexing error and matches Rust's nonempty result domain.

For each two-symbol column vector `[a,b]`, encryption returns `[(2a+5b) mod 36, (a+6b) mod 36]`. Decryption uses the fixed inverse key and returns `[(6a+25b) mod 36, (5a+26b) mod 36]`. Output is the resulting uppercase ASCII byte sequence. The function returns its byte length, `-1` for malformed or out-of-domain input, and `-2` for insufficient or null output capacity.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/hill_cipher_mod36.c`](../../../c/h/hill_cipher_mod36.c) |
| C3 | [`c3/h/hill_cipher_mod36.c3`](../../../c3/h/hill_cipher_mod36.c3) |
| C++ | [`cpp/h/hill_cipher_mod36.cpp`](../../../cpp/h/hill_cipher_mod36.cpp) |
| Elisa | [`elisa/h/hill_cipher_mod36.elisa`](../../../elisa/h/hill_cipher_mod36.elisa) |
| Nim | [`nim/h/hill_cipher_mod36.nim`](../../../nim/h/hill_cipher_mod36.nim) |
| Odin | [`odin/h/hill_cipher_mod36.odin`](../../../odin/h/hill_cipher_mod36.odin) |
| Rust | [`rust/h/hill_cipher_mod36.rs`](../../../rust/h/hill_cipher_mod36.rs) |
| V | [`v/h/hill_cipher_mod36.v`](../../../v/h/hill_cipher_mod36.v) |
| Zig | [`zig/h/hill_cipher_mod36.zig`](../../../zig/h/hill_cipher_mod36.zig) |
