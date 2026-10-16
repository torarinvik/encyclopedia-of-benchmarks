# ADFGVX cipher

Encrypt or decrypt bounded ASCII text with the pinned Java ADFGVX implementation.

## Contract

- Use the `i64_array_bytes_output` ABI. Pack input as `[mode, text_length, key_length, text bytes..., key bytes...]`; mode `0` encrypts and mode `1` decrypts.
- Encryption accepts up to 256 ASCII bytes. It uppercases ASCII letters, removes bytes outside `A-Z` and `0-9`, maps each remaining character through the source's 6×6 Polybius square, then reads the filled grid down columns in sorted-key order.
- Decryption accepts up to 512 ciphertext bytes, requires an even length, and accepts only `A`, `D`, `F`, `G`, `V`, and `X`. It reverses the source's sorted-column fill and maps each resulting label pair back through the same square.
- Keys contain 1 through 16 distinct uppercase ASCII letters. The source uses `key.indexOf` after sorting, so repeated characters would address the first matching column more than once; repeated-key inputs are excluded from this portable contract.
- Text bytes must be ASCII `[0,127]`. Output is ASCII bytes without a trailing NUL. Malformed or unsupported input returns `-1`; insufficient output capacity returns `-2`.

The square uses row and column labels `ADFGVX` and contains:

```text
N A 1 C 3 H
8 T B 2 O M
E 5 W R P D
4 F 6 G 7 I
9 J 0 K L Q
S U V X Y Z
```

The decryption port follows the Java helper's actual column-fill order, including its treatment of a partial final row. This preserves the pinned implementation for bounded inputs instead of substituting a different transposition convention. The Java source calls locale-sensitive `String.toUpperCase()`; this benchmark defines ASCII-only, locale-independent case folding so results stay stable across hosts. In a Turkish JVM locale, lowercase ASCII `i` can uppercase to `İ` and then be removed by the source regex, while this contract maps it to `I`.

## Workload and implementations

[`workload.json`](workload.json) covers the pinned `attack at 1200am` example in both directions, ASCII normalization, an empty message, and invalid mode, key, and ciphertext inputs. The shared `i64_array_bytes_output` runner validates the workload with its source-specific ADFGVX oracle before recording.

Run the independent cross-language verifier with:

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm adfgvxcipher
```

| Language | Source |
| --- | --- |
| C | [`c/a/adfgvxcipher.c`](../../../c/a/adfgvxcipher.c) |
| C3 | [`c3/a/adfgvxcipher.c3`](../../../c3/a/adfgvxcipher.c3) |
| C++ | [`cpp/a/adfgvxcipher.cpp`](../../../cpp/a/adfgvxcipher.cpp) |
| Elisa | [`elisa/a/adfgvxcipher.elisa`](../../../elisa/a/adfgvxcipher.elisa) |
| Nim | [`nim/a/adfgvxcipher.nim`](../../../nim/a/adfgvxcipher.nim) |
| Odin | [`odin/a/adfgvxcipher.odin`](../../../odin/a/adfgvxcipher.odin) |
| Rust | [`rust/a/adfgvxcipher.rs`](../../../rust/a/adfgvxcipher.rs) |
| V | [`v/a/adfgvxcipher.v`](../../../v/a/adfgvxcipher.v) |
| Zig | [`zig/a/adfgvxcipher.zig`](../../../zig/a/adfgvxcipher.zig) |

## Pinned source

- Java [`ADFGVXCipher.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/ADFGVXCipher.java)
