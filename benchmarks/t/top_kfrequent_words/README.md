# Top K Frequent Words with Lexicographic Ties

This benchmark follows the pinned Java `TopKFrequentWords.findTopKFrequentWords` comparator. It counts distinct input words, sorts by descending frequency, and resolves equal frequencies by ascending lexicographic order. This differs from the Python `top_k_frequent_words` package, whose frequency-only heap preserves heap-layout effects for ties.

## Contract

The `i64_array_bytes_output` input is `[k, word_count, (word_length, lowercase_ASCII_codes...)*]`. `k` and `word_count` are each in `0..64`; words contain 1..16 lowercase ASCII letters and the packed input contains at most 1,090 integers. Empty input and `k=0` produce an empty result; `k` larger than the distinct word count is clamped. Invalid packing returns `-1`; insufficient output capacity returns `-2`.

The output contains the selected words in rank order, each followed by LF, and ends with NUL. The result is the number of output bytes including NUL. Since the pinned Java comparator uses Java `String` natural order, lowercase ASCII ordering matches the bytewise order in this bounded contract.

The ports use a bounded binary heap with a composite priority that preserves the same total order: frequency first, then lexicographically smaller word. The fixed domain makes the priority unambiguous.

## Workload and oracle

[`workload.json`](workload.json) covers the pinned example, equal-frequency ties, partial selection, empty output, clamping, and malformed input. The runtime oracle is [`benchmarks/top_kfrequent_words_oracle.py`](../../top_kfrequent_words_oracle.py).

Pinned source: [TheAlgorithms/Java `TopKFrequentWords.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/TopKFrequentWords.java).

| Language | Port |
|---|---|
| C | [`c/t/top_kfrequent_words.c`](../../../c/t/top_kfrequent_words.c) |
| C3 | [`c3/t/top_kfrequent_words.c3`](../../../c3/t/top_kfrequent_words.c3) |
| C++ | [`cpp/t/top_kfrequent_words.cpp`](../../../cpp/t/top_kfrequent_words.cpp) |
| Elisa | [`elisa/t/top_kfrequent_words.elisa`](../../../elisa/t/top_kfrequent_words.elisa) |
| Nim | [`nim/t/top_kfrequent_words.nim`](../../../nim/t/top_kfrequent_words.nim) |
| Odin | [`odin/t/top_kfrequent_words.odin`](../../../odin/t/top_kfrequent_words.odin) |
| Rust | [`rust/t/top_kfrequent_words.rs`](../../../rust/t/top_kfrequent_words.rs) |
| V | [`v/t/top_kfrequent_words.v`](../../../v/t/top_kfrequent_words.v) |
| Zig | [`zig/t/top_kfrequent_words.zig`](../../../zig/t/top_kfrequent_words.zig) |
