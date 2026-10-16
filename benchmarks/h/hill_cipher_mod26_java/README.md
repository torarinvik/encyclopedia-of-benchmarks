# Java Hill cipher modulo 26

This benchmark ports the pinned Java `HillCipher` encrypt and decrypt methods with one fixed, invertible 2×2 key pair. The encrypt key is `[[3,3],[2,5]]`; its determinant is 9 and `gcd(9,26)=1`. The decrypt key is its modular inverse `[[15,17],[20,9]]`, whose determinant is -205 and is also coprime to 26. The key pair is fixed by the contract so the benchmark measures the block transform directly.

## Contract

Input is `[operation, ASCII character codes...]`, with operation 0 for encrypt and 1 for decrypt. The message is at most 256 ASCII bytes. ASCII lowercase letters become uppercase; all nonletters are discarded, matching the source's uppercase-then-`[^A-Z]` filtering for this bounded ASCII domain. A nonempty filtered message is padded with `X` to an even length. Empty filtered messages produce empty output.

Each block is a two-character column vector. The selected 2×2 matrix multiplies the vector modulo 26, with `A=0` through `Z=25`. Output is the resulting uppercase ASCII bytes; the return value is the byte count. Invalid input returns `-1`; insufficient capacity returns `-2` without writing.

The Java source rejects a determinant that is zero modulo 26. This package narrows its fixed key domain to matrices with determinant coprime to 26 so both encryption and the inverse-key decryption contract are valid.

[`workload.json`](workload.json) covers encryption, decryption, lowercase and punctuation filtering, X padding, empty filtered input, invalid values, and output capacity.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm hill_cipher_mod26_java --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/h/hill_cipher_mod26_java/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/hill_cipher_mod26_java.c`](../../../c/h/hill_cipher_mod26_java.c) |
| C3 | [`c3/h/hill_cipher_mod26_java.c3`](../../../c3/h/hill_cipher_mod26_java.c3) |
| C++ | [`cpp/h/hill_cipher_mod26_java.cpp`](../../../cpp/h/hill_cipher_mod26_java.cpp) |
| Elisa | [`elisa/h/hill_cipher_mod26_java.elisa`](../../../elisa/h/hill_cipher_mod26_java.elisa) |
| Nim | [`nim/h/hill_cipher_mod26_java.nim`](../../../nim/h/hill_cipher_mod26_java.nim) |
| Odin | [`odin/h/hill_cipher_mod26_java.odin`](../../../odin/h/hill_cipher_mod26_java.odin) |
| Rust | [`rust/h/hill_cipher_mod26_java.rs`](../../../rust/h/hill_cipher_mod26_java.rs) |
| V | [`v/h/hill_cipher_mod26_java.v`](../../../v/h/hill_cipher_mod26_java.v) |
| Zig | [`zig/h/hill_cipher_mod26_java.zig`](../../../zig/h/hill_cipher_mod26_java.zig) |

## Pinned source

- Java [`HillCipher.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/HillCipher.java)
