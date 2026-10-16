# Word patterns

`get_word_pattern` maps each character to the index of its first appearance and joins those indices with periods. The pinned Python implementation uppercases text before numbering. The benchmark preserves ASCII case folding and first-seen numbering while narrowing inputs to ASCII bytes, avoiding Python's Unicode uppercase expansion and code-point behavior.

## Contract

The ABI takes `[byte_length, bytes...]` in `i64_array_bytes_output`. Length is 0 through 256; each byte is ASCII 0 through 127. ASCII lowercase letters are normalized to uppercase; all other ASCII bytes compare exactly. Output is the decimal first-seen index of each normalized byte, with indices separated by `.` and a trailing NUL. Empty input produces only the NUL. Invalid packed lengths or bytes return `-1`; insufficient output capacity returns `-2`. Output needs at most 1025 bytes including the terminator.

The transformation runs in O(n) time and O(1) auxiliary space for the fixed ASCII alphabet.

[`workload.json`](workload.json) includes the pinned `pattern` example, case folding, repeated punctuation, empty input, and malformed bounds.

## Pinned source

- [Python `word_patterns.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/word_patterns.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/w/word_patterns.c`](../../../c/w/word_patterns.c) |
| C3 | [`c3/w/word_patterns.c3`](../../../c3/w/word_patterns.c3) |
| C++ | [`cpp/w/word_patterns.cpp`](../../../cpp/w/word_patterns.cpp) |
| Elisa | [`elisa/w/word_patterns.elisa`](../../../elisa/w/word_patterns.elisa) |
| Nim | [`nim/w/word_patterns.nim`](../../../nim/w/word_patterns.nim) |
| Odin | [`odin/w/word_patterns.odin`](../../../odin/w/word_patterns.odin) |
| Rust | [`rust/w/word_patterns.rs`](../../../rust/w/word_patterns.rs) |
| V | [`v/w/word_patterns.v`](../../../v/w/word_patterns.v) |
| Zig | [`zig/w/word_patterns.zig`](../../../zig/w/word_patterns.zig) |
