# Count Sentences

## Contract

Count the non-overlapping matches made by the pinned PHP regular expression after applying PHP's default `trim()` to an ASCII string. The `i64_array_scalar` ABI packs input as `[text_length, ASCII_bytes...]`. Text length is from 0 through 4,096 and each byte is from 0 through 127. Invalid packed input returns `-1`; an empty or trimmed-empty string returns 0.

The pinned expression is `/[^\s|^\.](\.|\!|\?)(?!\w)/`. On the bounded ASCII domain, each match consumes an eligible preceding byte followed by `.`, `!`, or `?`; the terminator must not be followed by an ASCII word byte (`A-Z`, `a-z`, `0-9`, or `_`). The preceding byte cannot be regex whitespace, `|`, `^`, or `.`. Matches do not overlap because `preg_match_all` advances past the two consumed bytes.

PHP's default trim set removes NUL, tab, line feed, vertical tab, carriage return, and space at either end. The regex `\s` class additionally excludes form feed as a preceding byte. The contract is ASCII-only so PHP/PCRE locale and Unicode character-class behavior do not vary across ports.

## Workload

[`workload.json`](workload.json) covers sentence punctuation, punctuation followed by word bytes, excluded preceding bytes, consecutive terminators, PHP trim boundaries, empty strings, malformed lengths, and invalid byte values.

## Pinned source

- PHP [`CountSentences.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Strings/CountSentences.php)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/count_sentences.c`](../../../c/c/count_sentences.c) |
| C3 | [`c3/c/count_sentences.c3`](../../../c3/c/count_sentences.c3) |
| C++ | [`cpp/c/count_sentences.cpp`](../../../cpp/c/count_sentences.cpp) |
| Elisa | [`elisa/c/count_sentences.elisa`](../../../elisa/c/count_sentences.elisa) |
| Nim | [`nim/c/count_sentences.nim`](../../../nim/c/count_sentences.nim) |
| Odin | [`odin/c/count_sentences.odin`](../../../odin/c/count_sentences.odin) |
| Rust | [`rust/c/count_sentences.rs`](../../../rust/c/count_sentences.rs) |
| V | [`v/c/count_sentences.v`](../../../v/c/count_sentences.v) |
| Zig | [`zig/c/count_sentences.zig`](../../../zig/c/count_sentences.zig) |
