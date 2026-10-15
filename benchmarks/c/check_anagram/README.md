# Check anagram

## Contract

Compare two ASCII alphabetic words case-insensitively. Return `1` when their
letter frequencies match and their normalized words are different; return `0`
otherwise. Thus `"coder"` and `"credo"` match, while `"Nim"` and `"nIM"` do
not, because case folding makes those words identical. Two empty strings return
`0`.

The packed `i64` input is
`[first_length, second_length, first_ascii_values..., second_ascii_values...]`.
Each length is in `0..=1024`; characters must be ASCII `A-Z` or `a-z`; and the
packed length must exactly match both declared lengths. Malformed lengths or
nonletters return `-1`. The input is not modified.

This follows the pinned Nim `isAnagram` behavior. The existing
[`valid_anagram`](../../v/valid_anagram/README.md) benchmark uses lowercase ASCII,
accepts a word as its own anagram, and treats two empty strings as anagrams.
The pinned JavaScript and PHP functions also use case-insensitive comparison,
but accept identical strings and support broader character sets. Those
contract differences make this a separate benchmark.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/check_anagram.c`](../../../c/c/check_anagram.c) |
| C3 | [`c3/c/check_anagram.c3`](../../../c3/c/check_anagram.c3) |
| C++ | [`cpp/c/check_anagram.cpp`](../../../cpp/c/check_anagram.cpp) |
| Elisa | [`elisa/c/check_anagram.elisa`](../../../elisa/c/check_anagram.elisa) |
| Nim | [`nim/c/check_anagram.nim`](../../../nim/c/check_anagram.nim) |
| Odin | [`odin/c/check_anagram.odin`](../../../odin/c/check_anagram.odin) |
| Rust | [`rust/c/check_anagram.rs`](../../../rust/c/check_anagram.rs) |
| V | [`v/c/check_anagram.v`](../../../v/c/check_anagram.v) |
| Zig | [`zig/c/check_anagram.zig`](../../../zig/c/check_anagram.zig) |

## TheAlgorithms references

- [Nim `check_anagram.nim`](https://github.com/TheAlgorithms/Nim/blob/63eec16614b46c91078653e8d3c049fe99ad36b3/strings/check_anagram.nim)
- [JavaScript `CheckAnagram.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/CheckAnagram.js)
- [PHP `CheckAnagram.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Strings/CheckAnagram.php)
