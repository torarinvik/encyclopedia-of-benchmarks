# Uncommon Words

This benchmark follows the pinned Ruby `find_uncommon_words` routine: count each word across both sentences and return the words whose total count is exactly one. The Ruby Hash preserves first insertion order, so the adapter keeps first-seen order. The packed input normalizes the two sentences to their combined token sequence; sentence boundaries do not affect total-frequency results.

## Contract

Input is `[word_count, (word_length, lowercase_ASCII_codes...)*]` in the `i64_array_bytes_output` ABI. There are at most 64 words, each 1..16 lowercase ASCII letters. Invalid input returns `-1`; insufficient output capacity returns `-2`.

Output contains every word occurring exactly once, in first-occurrence order, with LF separators and a final NUL byte. An empty result is a single NUL byte. Success returns output byte length including the NUL.

## Workload and source

[`workload.json`](workload.json) covers both pinned examples, repeated words, empty input, and malformed words. The runtime oracle is [`benchmarks/uncommon_words_oracle.py`](../../uncommon_words_oracle.py).

Pinned source: [TheAlgorithms/Ruby `uncommon_words.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/hash_table/uncommon_words.rb).

| Language | Port |
|---|---|
| C | [`c/u/uncommon_words.c`](../../../c/u/uncommon_words.c) |
| C3 | [`c3/u/uncommon_words.c3`](../../../c3/u/uncommon_words.c3) |
| C++ | [`cpp/u/uncommon_words.cpp`](../../../cpp/u/uncommon_words.cpp) |
| Elisa | [`elisa/u/uncommon_words.elisa`](../../../elisa/u/uncommon_words.elisa) |
| Nim | [`nim/u/uncommon_words.nim`](../../../nim/u/uncommon_words.nim) |
| Odin | [`odin/u/uncommon_words.odin`](../../../odin/u/uncommon_words.odin) |
| Rust | [`rust/u/uncommon_words.rs`](../../../rust/u/uncommon_words.rs) |
| V | [`v/u/uncommon_words.v`](../../../v/u/uncommon_words.v) |
| Zig | [`zig/u/uncommon_words.zig`](../../../zig/u/uncommon_words.zig) |
