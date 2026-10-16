# Top K frequent words

## Contract

This benchmark follows the pinned Python `top_k_frequent_words` routine. It counts distinct input words in first-occurrence order, builds a max heap, and extracts up to `k` words. The heap compares frequency only. Its strict comparisons preserve heap-layout effects for ties; ties are not sorted alphabetically or guaranteed to be stable. For example, three first-seen words `a,b,c` with equal counts are extracted as `a,c,b`.

The packed signed 64-bit input is `[k, word_count, (word_length, lowercase_ASCII_codes...)*]`. `k` and `word_count` are each in `0..64`; each word has 1..16 bytes, all lowercase ASCII `a..z`; the packed input has at most 1,090 values. Empty input lists and `k=0` return an empty list. `k` larger than the number of distinct words is clamped. Malformed input returns `-1`; insufficient output capacity returns `-2`.

Because the ABI returns bytes, ranked words are encoded as each word followed by LF, then a final NUL byte. Words are nonempty and lowercase, so LF cannot occur in a word. The return value is the number of bytes written, including the final NUL.

This is a ranked list of distinct words. It differs from `average_mode`, which returns one numeric mode, `word_count`, which counts a requested word, and majority-element benchmarks, which return one value only when it exceeds half the input. Ruby's `max_k_most_frequent_words` uses the same frequency-only heap approach. Java's `top_kfrequent_words` instead resolves ties by lexicographic order, so it is a related but numerically different tie contract.

The benchmark uses a bounded lowercase-ASCII word domain and a fixed-width count cap to keep all nine ports allocation-free. It preserves the Python heap's bottom-up construction, left-before-right strict comparison, and root replacement on extraction.

## Workload and implementation

[`workload.json`](workload.json) includes source examples, equal-frequency heap-order ties, `k=0`, clamping, empty input, and malformed packing.

| Language | Source |
| --- | --- |
| C | [`c/t/top_k_frequent_words.c`](../../../c/t/top_k_frequent_words.c) |
| C3 | [`c3/t/top_k_frequent_words.c3`](../../../c3/t/top_k_frequent_words.c3) |
| C++ | [`cpp/t/top_k_frequent_words.cpp`](../../../cpp/t/top_k_frequent_words.cpp) |
| Elisa | [`elisa/t/top_k_frequent_words.elisa`](../../../elisa/t/top_k_frequent_words.elisa) |
| Nim | [`nim/t/top_k_frequent_words.nim`](../../../nim/t/top_k_frequent_words.nim) |
| Odin | [`odin/t/top_k_frequent_words.odin`](../../../odin/t/top_k_frequent_words.odin) |
| Rust | [`rust/t/top_k_frequent_words.rs`](../../../rust/t/top_k_frequent_words.rs) |
| V | [`v/t/top_k_frequent_words.v`](../../../v/t/top_k_frequent_words.v) |
| Zig | [`zig/t/top_k_frequent_words.zig`](../../../zig/t/top_k_frequent_words.zig) |

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm top_k_frequent_words --language rust
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm top_k_frequent_words
```

## Pinned sources

- [Python `top_k_frequent_words.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/top_k_frequent_words.py)
- [Python `heap.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/heap/heap.py)
- [Ruby `max_k_most_frequent_words.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/strings/max_k_most_frequent_words.rb)
- [Ruby `max_heap.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/heaps/max_heap.rb)
- [Java `TopKFrequentWords.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/TopKFrequentWords.java)
