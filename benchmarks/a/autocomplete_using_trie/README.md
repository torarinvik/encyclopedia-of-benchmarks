# Autocomplete Using Trie

This package ports the pinned Python and Rust trie implementations for prefix autocomplete. The Python source uses a terminal `#` marker and appends a trailing space to returned words; the Rust source stores terminators in hash maps, so iteration order is unspecified. The benchmark normalizes terminal markers away and sorts unique completions.

## Contract

Input is a signed 64-bit array `[word_count, (word_length, ASCII codes...)..., query_count, (prefix_length, ASCII codes...)...]`. There are 0 to 32 inserted words, each 1 to 16 lowercase ASCII letters, and 0 to 16 prefixes, each 0 to 16 lowercase ASCII letters. Duplicate inserted words are accepted and deduplicated. An empty prefix matches every inserted word. Non-lowercase characters are invalid. Input length must match all declared strings exactly.

Output is a little-endian signed i64 vector: it begins with the query count, then for each query contains its completion count followed by each matching word as `[word_length, ASCII codes...]`. Completions are unique and sorted in ascending lexicographic order. The function returns bytes written; malformed input returns `-1`; a null or undersized output buffer returns `-2` without writing.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm autocomplete_using_trie --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/a/autocomplete_using_trie/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/autocomplete_using_trie.c`](../../../c/a/autocomplete_using_trie.c) |
| C3 | [`c3/a/autocomplete_using_trie.c3`](../../../c3/a/autocomplete_using_trie.c3) |
| C++ | [`cpp/a/autocomplete_using_trie.cpp`](../../../cpp/a/autocomplete_using_trie.cpp) |
| Elisa | [`elisa/a/autocomplete_using_trie.elisa`](../../../elisa/a/autocomplete_using_trie.elisa) |
| Nim | [`nim/a/autocomplete_using_trie.nim`](../../../nim/a/autocomplete_using_trie.nim) |
| Odin | [`odin/a/autocomplete_using_trie.odin`](../../../odin/a/autocomplete_using_trie.odin) |
| Rust | [`rust/a/autocomplete_using_trie.rs`](../../../rust/a/autocomplete_using_trie.rs) |
| V | [`v/a/autocomplete_using_trie.v`](../../../v/a/autocomplete_using_trie.v) |
| Zig | [`zig/a/autocomplete_using_trie.zig`](../../../zig/a/autocomplete_using_trie.zig) |

## Pinned sources

- Python [`strings/autocomplete_using_trie.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/autocomplete_using_trie.py)
- Rust [`src/string/autocomplete_using_trie.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/autocomplete_using_trie.rs)
