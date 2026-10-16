# Columnar Transposition

This benchmark follows TheAlgorithms/Python's `encrypt` and `decrypt` functions. It writes text into unpadded ragged rows, reads columns in stable alphabetical key order, and preserves spaces and punctuation. Key normalization uppercases ASCII letters and drops other ASCII characters; duplicate letters retain their original order.

## Contract

- Input is `[operation, text_length, raw_key_length, text_bytes..., raw_key_bytes...]`. Operation `0` encrypts and operation `1` decrypts.
- Text length is 0 through 256 bytes; raw key length is 1 through 32 ASCII bytes. Text and key bytes must be ASCII. Normalization keeps A-Z letters, uppercases a-z, and ignores other key bytes; at least one letter must remain.
- Encryption and decryption return raw text bytes. Invalid input returns `-1`; insufficient capacity for a nonempty result returns `-2`. Empty text returns zero bytes. This uses portable scalar indexing and byte operations.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm columnar_transposition --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/c/columnar_transposition/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/columnar_transposition.c`](../../../c/c/columnar_transposition.c) |
| C3 | [`c3/c/columnar_transposition.c3`](../../../c3/c/columnar_transposition.c3) |
| C++ | [`cpp/c/columnar_transposition.cpp`](../../../cpp/c/columnar_transposition.cpp) |
| Elisa | [`elisa/c/columnar_transposition.elisa`](../../../elisa/c/columnar_transposition.elisa) |
| Nim | [`nim/c/columnar_transposition.nim`](../../../nim/c/columnar_transposition.nim) |
| Odin | [`odin/c/columnar_transposition.odin`](../../../odin/c/columnar_transposition.odin) |
| Rust | [`rust/c/columnar_transposition.rs`](../../../rust/c/columnar_transposition.rs) |
| V | [`v/c/columnar_transposition.v`](../../../v/c/columnar_transposition.v) |
| Zig | [`zig/c/columnar_transposition.zig`](../../../zig/c/columnar_transposition.zig) |

## Pinned source

- Python [`columnar_transposition.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/columnar_transposition.py)
