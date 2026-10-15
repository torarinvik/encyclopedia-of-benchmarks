# Anagram Dictionary Search

This benchmark returns every entry in a supplied word list whose character-frequency signature matches the query word. It ports the lookup core from Python `anagrams.py`; the source's 235,886-line dictionary is supplied as benchmark input so the ports share a bounded, explicit data set. The dictionary must be sorted and unique, as in the source's normalized word list.

## Contract

- Input is `[dictionary_count, query_length, query_bytes..., word_length, word_bytes..., ...]`.
- The dictionary has at most 16 nonempty words, each at most 16 lowercase ASCII letters. The lowercase query may be empty or contain up to 16 letters.
- Matches preserve dictionary order and are emitted one per line as ASCII bytes, followed by NUL. No matches produce a single NUL byte.
- Return `-1` for malformed input and `-2` when the output buffer is too small.

The Python source builds a map from sorted character-frequency signatures to sorted dictionary words. This contract exposes the corresponding query and dictionary inputs directly rather than embedding the upstream word list.

| Language | Source |
|---|---|
| C | [`c/a/anagram_dictionary_search.c`](../../../c/a/anagram_dictionary_search.c) |
| C3 | [`c3/a/anagram_dictionary_search.c3`](../../../c3/a/anagram_dictionary_search.c3) |
| C++ | [`cpp/a/anagram_dictionary_search.cpp`](../../../cpp/a/anagram_dictionary_search.cpp) |
| Elisa | [`elisa/a/anagram_dictionary_search.elisa`](../../../elisa/a/anagram_dictionary_search.elisa) |
| Nim | [`nim/a/anagram_dictionary_search.nim`](../../../nim/a/anagram_dictionary_search.nim) |
| Odin | [`odin/a/anagram_dictionary_search.odin`](../../../odin/a/anagram_dictionary_search.odin) |
| Rust | [`rust/a/anagram_dictionary_search.rs`](../../../rust/a/anagram_dictionary_search.rs) |
| V | [`v/a/anagram_dictionary_search.v`](../../../v/a/anagram_dictionary_search.v) |
| Zig | [`zig/a/anagram_dictionary_search.zig`](../../../zig/a/anagram_dictionary_search.zig) |

## Sources

- [Python `strings/anagrams.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/anagrams.py)
- [Python `strings/words.txt`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/words.txt)
