# Shortest word distance

This benchmark follows the pinned Ruby nested scan. It compares all positions containing either target and returns the minimum absolute index difference. The Ruby source returns 0 when the targets are equal or either target is absent; those cases are outside this shared benchmark domain. Valid inputs require two distinct targets that both occur in the word list.

## Contract

Input is a signed 64-bit array `[word_count, (word_length, ASCII_letter_bytes...)*, target1_length, target1_bytes..., target2_length, target2_bytes...]`. There are 2 through 32 words, each 1 through 8 ASCII letters (`A-Z` or `a-z`). Both target words are 1 through 8 ASCII letters (`A-Z` or `a-z`), distinct, and present in the list. Input length must exactly match the packed records.

The result is the smallest absolute difference between an index of `target1` and an index of `target2`. Invalid framing, out-of-domain words, equal targets, missing targets, and null input return `-1`. The workload includes the pinned Ruby examples, repeated occurrences, case sensitivity, bounds, malformed records, and the source's outside-domain cases.

The independent [oracle](../../shortest_word_distance_oracle.py) and [`workload.json`](workload.json) define the bounded input domain.

## Pinned source

- [TheAlgorithms/Ruby `shortest_word_distance.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/shortest_word_distance.rb)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/shortest_word_distance.c`](../../../c/s/shortest_word_distance.c) |
| C3 | [`c3/s/shortest_word_distance.c3`](../../../c3/s/shortest_word_distance.c3) |
| C++ | [`cpp/s/shortest_word_distance.cpp`](../../../cpp/s/shortest_word_distance.cpp) |
| Elisa | [`elisa/s/shortest_word_distance.elisa`](../../../elisa/s/shortest_word_distance.elisa) |
| Nim | [`nim/s/shortest_word_distance.nim`](../../../nim/s/shortest_word_distance.nim) |
| Odin | [`odin/s/shortest_word_distance.odin`](../../../odin/s/shortest_word_distance.odin) |
| Rust | [`rust/s/shortest_word_distance.rs`](../../../rust/s/shortest_word_distance.rs) |
| V | [`v/s/shortest_word_distance.v`](../../../v/s/shortest_word_distance.v) |
| Zig | [`zig/s/shortest_word_distance.zig`](../../../zig/s/shortest_word_distance.zig) |
