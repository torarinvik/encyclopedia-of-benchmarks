# Word Frequency BST

Count ASCII words and emit the distinct words in alphabetical order using an
unbalanced binary search tree.

## Contract

The pinned C source lowercases alphabetic bytes, tokenizes words with its
letter/apostrophe/hyphen rule, inserts or increments nodes through `strcmp`,
and writes the tree in in-order traversal. The benchmark preserves that parser
and BST behavior while excluding the source's self-test, file I/O, header, and
process-global serial number. It emits each sorted record as
`word<TAB>frequency<LF>` with no NUL terminator.

The `i64_array_bytes_output` ABI input is `[text_length, byte_0, ...]`, with
exact length `text_length + 1`, `0 <= text_length <= 256`, and each byte in
`0..=127`. This ASCII-only domain makes letter classification and lowercase
conversion deterministic. Alphabetic bytes are lowercased. An apostrophe or
hyphen is appended only after a letter; other bytes delimit words. A trailing
hyphen is removed when a token is flushed, while a trailing apostrophe is
kept. The leading apostrophes/hyphens are delimiters. A token may contain at
most 45 bytes, matching the pinned 46-byte buffer including its terminator;
longer tokens are invalid rather than split or truncated. At most 128 distinct
words are accepted, bounding the tree's worst-case depth.

The output is sorted by ASCII byte order, with one lowercase word, a tab, its
decimal occurrence count, and a newline per unique word. There is no header or
serial index. The maximum output is 896 bytes. Invalid frames, non-ASCII
values, overlong tokens, or excess distinct words return `-1` before output
storage is checked. A null output pointer or insufficient capacity returns
`-2` without writes. Empty text succeeds with zero output bytes when a nonnull
output pointer is supplied. The oracle uses a Python frequency map and sort,
independently of the tree representation.

The pinned self-test writes an actual newline in its sample file text, but its
hard-coded expected text also includes an `n` word. This benchmark follows the
tokenizer and BST core; the newline is a delimiter and does not produce `n`.

## Workload

[`workload.json`](workload.json) covers the pinned example, case folding,
punctuation edges, maximum input and token sizes, malformed input, and output
storage errors. The [oracle](../../word_frequency_bst_oracle.py) computes
frequencies independently of the BST ports.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/w/word_frequency_bst.c`](../../../c/w/word_frequency_bst.c) |
| C3 | [`c3/w/word_frequency_bst.c3`](../../../c3/w/word_frequency_bst.c3) |
| C++ | [`cpp/w/word_frequency_bst.cpp`](../../../cpp/w/word_frequency_bst.cpp) |
| Elisa | [`elisa/w/word_frequency_bst.elisa`](../../../elisa/w/word_frequency_bst.elisa) |
| Nim | [`nim/w/word_frequency_bst.nim`](../../../nim/w/word_frequency_bst.nim) |
| Odin | [`odin/w/word_frequency_bst.odin`](../../../odin/w/word_frequency_bst.odin) |
| Rust | [`rust/w/word_frequency_bst.rs`](../../../rust/w/word_frequency_bst.rs) |
| V | [`v/w/word_frequency_bst.v`](../../../v/w/word_frequency_bst.v) |
| Zig | [`zig/w/word_frequency_bst.zig`](../../../zig/w/word_frequency_bst.zig) |

## Pinned source

- TheAlgorithms/C [`words_alphabetical.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/binary_trees/words_alphabetical.c) at `e5dad3fa8def3726ec850ca66a7f51521f8ad393`, symbol `addWordToTree` and the tokenizer in `readWordsInFileToTree`.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm word_frequency_bst --language c
python3 benchmarks/run_i64_array_bytes_output.py --algorithm word_frequency_bst
```
