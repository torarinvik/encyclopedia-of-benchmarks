# Detect Anagrams

This benchmark ports the Julia `detect_anagrams(subject, candidates)` filter. It returns candidates whose lowercase character-frequency signature matches the subject, excluding any candidate equal to the subject after lowercasing. Matching candidates remain in input order, including repeated candidate strings.

## Contract

- Input is `[subject_length, subject_bytes..., candidate_count, candidate_length, candidate_bytes..., ...]`.
- The subject and each candidate contain 0 through 16 ASCII English letters (`A-Z` or `a-z`); there are at most 16 candidates.
- Return the number of matches. Output each original candidate, followed by newline, then a NUL byte. No matches produce a single NUL byte.
- Invalid input returns `-1`; insufficient output capacity returns `-2`.

The C ABI entry point is:

```c
int64_t detect_anagrams(const int64_t *input, size_t length,
                        uint8_t *output, size_t capacity);
```

| Language | Source |
|---|---|
| C | [`c/d/detect_anagrams.c`](../../../c/d/detect_anagrams.c) |
| C3 | [`c3/d/detect_anagrams.c3`](../../../c3/d/detect_anagrams.c3) |
| C++ | [`cpp/d/detect_anagrams.cpp`](../../../cpp/d/detect_anagrams.cpp) |
| Elisa | [`elisa/d/detect_anagrams.elisa`](../../../elisa/d/detect_anagrams.elisa) |
| Nim | [`nim/d/detect_anagrams.nim`](../../../nim/d/detect_anagrams.nim) |
| Odin | [`odin/d/detect_anagrams.odin`](../../../odin/d/detect_anagrams.odin) |
| Rust | [`rust/d/detect_anagrams.rs`](../../../rust/d/detect_anagrams.rs) |
| V | [`v/d/detect_anagrams.v`](../../../v/d/detect_anagrams.v) |
| Zig | [`zig/d/detect_anagrams.zig`](../../../zig/d/detect_anagrams.zig) |

## Source

- [Julia `detect_anagrams.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/strings/detect_anagrams.jl)
- [Valid anagram predicate benchmark](../../v/valid_anagram/README.md)
- [Anagram dictionary search benchmark](../../a/anagram_dictionary_search/README.md)
