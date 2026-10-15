# Percentage of letters

Return the percentage of a string that matches a target letter, rounded down to the nearest whole percent. This follows the pinned JavaScript source on a bounded ASCII domain.

## Contract

- ABI: `i64_array_scalar`, with packed input `[target, text_codepoints...]`.
- The target must be one ASCII letter (`A`–`Z` or `a`–`z`). Text code points may be any ASCII value from 0 through 127.
- Text length is 1 through 4,096 code points. ASCII letters compare case-insensitively; other ASCII characters are allowed and do not match a letter target.
- Return `floor(100 * matching_code_points / text_length)`. Return `-1` for an invalid target, non-ASCII values, an empty or missing text, or a text longer than 4,096 code points.

The source uses JavaScript strings and lowercases each indexed character before comparing it with the target. Unicode code-point and UTF-16 edge cases are outside this ASCII contract.

[`workload.json`](workload.json) covers the source example, mixed case, no matches, all matches, punctuation, maximum text length, and invalid bounds.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/percentage_of_letters.c`](../../../c/p/percentage_of_letters.c) |
| C3 | [`c3/p/percentage_of_letters.c3`](../../../c3/p/percentage_of_letters.c3) |
| C++ | [`cpp/p/percentage_of_letters.cpp`](../../../cpp/p/percentage_of_letters.cpp) |
| Elisa | [`elisa/p/percentage_of_letters.elisa`](../../../elisa/p/percentage_of_letters.elisa) |
| Nim | [`nim/p/percentage_of_letters.nim`](../../../nim/p/percentage_of_letters.nim) |
| Odin | [`odin/p/percentage_of_letters.odin`](../../../odin/p/percentage_of_letters.odin) |
| Rust | [`rust/p/percentage_of_letters.rs`](../../../rust/p/percentage_of_letters.rs) |
| V | [`v/p/percentage_of_letters.v`](../../../v/p/percentage_of_letters.v) |
| Zig | [`zig/p/percentage_of_letters.zig`](../../../zig/p/percentage_of_letters.zig) |

## Pinned source

- [JavaScript `String/PercentageOfLetters.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/PercentageOfLetters.js)
