# Count vowels and consonants

This benchmark ports the pinned Python `count_vowels_and_consonants` function over bounded ASCII input. It counts `a`, `e`, `i`, `o`, and `u` in either case as vowels, counts other ASCII letters as consonants, and ignores nonletters.

## Contract

- The `i64_array_scalar_call` ABI represents the text as one ASCII code point per signed 64-bit array value.
- Inputs contain at most 100,000 code points, each in `[0, 127]`. Code points outside ASCII return `-1`; the source supports Unicode letters, which are outside this benchmark's bounded domain.
- The two nonnegative counts are packed as `vowel_count * 2^32 + consonant_count`. Each count is less than `2^32`, so the encoding is unambiguous.
- Empty input returns `0`.

[`workload.json`](workload.json) covers the pinned examples, mixed case, punctuation and digits, empty input, and an out-of-domain code point.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/count_vowels_consonants.c`](../../../c/c/count_vowels_consonants.c) |
| C3 | [`c3/c/count_vowels_consonants.c3`](../../../c3/c/count_vowels_consonants.c3) |
| C++ | [`cpp/c/count_vowels_consonants.cpp`](../../../cpp/c/count_vowels_consonants.cpp) |
| Elisa | [`elisa/c/count_vowels_consonants.elisa`](../../../elisa/c/count_vowels_consonants.elisa) |
| Nim | [`nim/c/count_vowels_consonants.nim`](../../../nim/c/count_vowels_consonants.nim) |
| Odin | [`odin/c/count_vowels_consonants.odin`](../../../odin/c/count_vowels_consonants.odin) |
| Rust | [`rust/c/count_vowels_consonants.rs`](../../../rust/c/count_vowels_consonants.rs) |
| V | [`v/c/count_vowels_consonants.v`](../../../v/c/count_vowels_consonants.v) |
| Zig | [`zig/c/count_vowels_consonants.zig`](../../../zig/c/count_vowels_consonants.zig) |

## Upstream source

- [TheAlgorithms/Python `count_vowels_consonants.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/count_vowels_consonants.py)
