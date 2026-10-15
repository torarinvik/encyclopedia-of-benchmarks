# Brute-force Caesar cipher

Try every Caesar decryption shift from 0 through 25. The pinned Python `decrypt` helper shifts uppercase ASCII letters backward by the current key and preserves all other characters. The source prints each result with a key label.

## Contract

The `i64_array_bytes_output` ABI accepts 0 to 64 ASCII byte values in `0..127`. It emits the 26 candidate plaintexts in key order as rows separated by LF bytes, with no trailing LF. The row index is the key, starting at 0. The ABI result is 26, the number of candidates. Invalid input returns `-1`; a null output pointer or insufficient capacity returns `-2` without writing. This compact output omits the source's display labels while retaining every candidate plaintext and its order.

## Workload and source

[`workload.json`](workload.json) covers the pinned example, the key-12 plaintext, wraparound, unchanged non-uppercase and control bytes, maximum length, malformed inputs, and insufficient output capacity.

- Python [`brute_force_caesar_cipher.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/brute_force_caesar_cipher.py)

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm brute_force_caesar_cipher --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/brute_force_caesar_cipher/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/b/brute_force_caesar_cipher.c`](../../../c/b/brute_force_caesar_cipher.c) |
| C3 | [`c3/b/brute_force_caesar_cipher.c3`](../../../c3/b/brute_force_caesar_cipher.c3) |
| C++ | [`cpp/b/brute_force_caesar_cipher.cpp`](../../../cpp/b/brute_force_caesar_cipher.cpp) |
| Elisa | [`elisa/b/brute_force_caesar_cipher.elisa`](../../../elisa/b/brute_force_caesar_cipher.elisa) |
| Nim | [`nim/b/brute_force_caesar_cipher.nim`](../../../nim/b/brute_force_caesar_cipher.nim) |
| Odin | [`odin/b/brute_force_caesar_cipher.odin`](../../../odin/b/brute_force_caesar_cipher.odin) |
| Rust | [`rust/b/brute_force_caesar_cipher.rs`](../../../rust/b/brute_force_caesar_cipher.rs) |
| V | [`v/b/brute_force_caesar_cipher.v`](../../../v/b/brute_force_caesar_cipher.v) |
| Zig | [`zig/b/brute_force_caesar_cipher.zig`](../../../zig/b/brute_force_caesar_cipher.zig) |
