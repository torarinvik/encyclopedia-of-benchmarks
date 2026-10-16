# Baconian cipher

This benchmark handles the encode and decode operations in the pinned Java, Python, and Rust sources. The sources use different Baconian alphabet tables, so the input includes a dialect selector and each dialect keeps its table and source-specific character handling.

## Contract

- Input is `[mode, dialect, payload_bytes...]`. Mode `0` encodes; mode `1` decodes. Dialect `0` is Java, `1` is Python, and `2` is Rust. Payload length is at most 1,024 bytes and values are ASCII `0..127`.
- Java encoding uses locale-independent ASCII case folding, drops nonletters, and maps both `I` and `J` to code 9. Java decoding accepts complete uppercase A/B groups with values 0 through 25; both codes 8 and 9 decode to `I`.
- Python encoding is case-insensitive, accepts letters and spaces, and preserves spaces. It retains the source's table, including `J = BBBAA` and `V = BBBAB`. Python decoding accepts only uppercase A/B and spaces, requires complete table codes inside space-delimited words, returns lowercase letters, and collapses repeated/edge spaces as `split()` does.
- Rust encoding maps `A..X` to the source's 24 codes and passes other ASCII bytes through. `Y` and `Z` are outside the supported domain because the pinned Rust table would index past its end. Rust decoding groups every five bytes, maps the 24 known groups to uppercase `A..X`, and returns a space for unknown or short groups.
- Malformed inputs and unsupported dialect values return `-1`; insufficient output capacity returns `-2`. The function returns the output byte length. Decoded Java/Rust letters are uppercase; Python letters are lowercase.

[`workload.json`](workload.json) covers the source examples, the three alphabet rules, both operations, malformed groups, source-specific fallback behavior, and maximum input sizes. The contract is distinct from Morse, A1Z26, and the other local ciphers because it uses fixed five-symbol A/B groups and a reversible alphabet substitution.

## Reviewed sources

- [Java `BaconianCipher.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/BaconianCipher.java)
- [Python `baconian_cipher.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/baconian_cipher.py)
- [Rust `baconian_cipher.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/baconian_cipher.rs)

## Implementations

- C: [`c/b/baconian_cipher.c`](../../../c/b/baconian_cipher.c)
- C3: [`c3/b/baconian_cipher.c3`](../../../c3/b/baconian_cipher.c3)
- C++: [`cpp/b/baconian_cipher.cpp`](../../../cpp/b/baconian_cipher.cpp)
- Elisa: [`elisa/b/baconian_cipher.elisa`](../../../elisa/b/baconian_cipher.elisa)
- Nim: [`nim/b/baconian_cipher.nim`](../../../nim/b/baconian_cipher.nim)
- Odin: [`odin/b/baconian_cipher.odin`](../../../odin/b/baconian_cipher.odin)
- Rust: [`rust/b/baconian_cipher.rs`](../../../rust/b/baconian_cipher.rs)
- V: [`v/b/baconian_cipher.v`](../../../v/b/baconian_cipher.v)
- Zig: [`zig/b/baconian_cipher.zig`](../../../zig/b/baconian_cipher.zig)

Build with the `i64_array_bytes_output` ABI family and record with `benchmarks/run_i64_array_bytes_output.py`.
The output workspace is 5,120 bytes, enough for 1,024 five-symbol encodings. Verify all nine ports with `python3 benchmarks/verify_i64_array_bytes_output.py --algorithm baconian_cipher`.
