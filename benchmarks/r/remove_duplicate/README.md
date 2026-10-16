# Remove Duplicate Words

This benchmark ports the pinned Python routine that splits a sentence into whitespace-delimited words, removes duplicates, sorts the words, and rejoins them with one space.

The shared contract uses a bounded lowercase-ASCII domain: input is `[text_length, bytes...]`, with letters `a` through `z` and ASCII spaces, and a maximum text length of 1,024 bytes. Multiple, leading, and trailing spaces are accepted. Empty text returns empty output. Invalid packed input returns -1. Output bytes are lexicographically sorted unique words separated by single spaces.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm remove_duplicate --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/r/remove_duplicate/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/remove_duplicate.c`](../../../c/r/remove_duplicate.c) |
| C3 | [`c3/r/remove_duplicate.c3`](../../../c3/r/remove_duplicate.c3) |
| C++ | [`cpp/r/remove_duplicate.cpp`](../../../cpp/r/remove_duplicate.cpp) |
| Elisa | [`elisa/r/remove_duplicate.elisa`](../../../elisa/r/remove_duplicate.elisa) |
| Nim | [`nim/r/remove_duplicate.nim`](../../../nim/r/remove_duplicate.nim) |
| Odin | [`odin/r/remove_duplicate.odin`](../../../odin/r/remove_duplicate.odin) |
| Rust | [`rust/r/remove_duplicate.rs`](../../../rust/r/remove_duplicate.rs) |
| V | [`v/r/remove_duplicate.v`](../../../v/r/remove_duplicate.v) |
| Zig | [`zig/r/remove_duplicate.zig`](../../../zig/r/remove_duplicate.zig) |

## Pinned source

- Python [`strings/remove_duplicate.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/remove_duplicate.py)
