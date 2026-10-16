# Word Pattern Matcher

The pinned Java backtracking matcher asks whether a pattern's symbols can be assigned distinct, nonempty substrings that concatenate to the entire input. Each symbol must reuse one substring consistently, and different symbols cannot share a substring. This is distinct from [`word_patterns`](../word_patterns/README.md), which assigns first-seen integer labels to individual characters.

## Contract

The `i64_array_bytes_output` ABI packs `[pattern_length, pattern bytes..., text_length, text bytes...]`. Pattern length is 0..8, text length is 0..32, and bytes are printable ASCII (32..126). Return 1 for a bijective pattern-to-substring match and 0 otherwise. The output buffer is unused. Empty pattern matches empty text. Malformed arrays return -1.

The bounded backtracking search tries each possible nonempty prefix for an unmapped pattern symbol, while tracking both symbol-to-substring and substring-to-symbol mappings. The maximum pattern length bounds the search.

## Pinned source

[Java `WordPatternMatcher.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/backtracking/WordPatternMatcher.java)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/w/word_pattern_matcher.c`](../../../c/w/word_pattern_matcher.c) |
| C3 | [`c3/w/word_pattern_matcher.c3`](../../../c3/w/word_pattern_matcher.c3) |
| C++ | [`cpp/w/word_pattern_matcher.cpp`](../../../cpp/w/word_pattern_matcher.cpp) |
| Elisa | [`elisa/w/word_pattern_matcher.elisa`](../../../elisa/w/word_pattern_matcher.elisa) |
| Nim | [`nim/w/word_pattern_matcher.nim`](../../../nim/w/word_pattern_matcher.nim) |
| Odin | [`odin/w/word_pattern_matcher.odin`](../../../odin/w/word_pattern_matcher.odin) |
| Rust | [`rust/w/word_pattern_matcher.rs`](../../../rust/w/word_pattern_matcher.rs) |
| V | [`v/w/word_pattern_matcher.v`](../../../v/w/word_pattern_matcher.v) |
| Zig | [`zig/w/word_pattern_matcher.zig`](../../../zig/w/word_pattern_matcher.zig) |

## Workload

See [`workload.json`](workload.json) for the pinned examples, repeated symbols, bijection and malformed-input cases.
