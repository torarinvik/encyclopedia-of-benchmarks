# McCAT Trie

This package ports the trie benchmark from `McCat/15-trie` in the pinned LAC-DCC Benchmarks inventory. The source reads whitespace-delimited tokens, inserts each token into a character trie, then prints the words by recursively visiting the matching-character continuation before the next-character alternative. Repeated words only set the terminal flag again, so they print once.

## Bounded suite contract

The `i64_array_bytes_output` function `mccat_trie` accepts `[word_count, word_length_0, byte_0, ..., word_length_n, byte_n, ...]`. There may be 0 through 64 words; each word has 1 through 32 bytes; each byte is visible non-whitespace ASCII (`33..126`). This profile matches the source's token input while bounding trie nodes, recursion depth, and output size. Input length must match the packed records exactly.

Output is the byte sequence printed by the source traversal: each distinct word followed by LF. Alternative characters stay in first-inserted order, so output is not globally sorted. Duplicate words are emitted once. The output is not NUL-terminated. Success returns its exact byte length; malformed input returns `-1`; a null output buffer or insufficient capacity for nonempty output returns `-2` without writing. Empty input returns zero bytes and length zero.

The largest valid input has 2,113 signed values. The output capacity is at most 2,112 bytes. Runtime and storage are O(total input characters), with the same continuation/alternative links as the source trie.

## Pinned source and terms

- Launcher: [`McCat/15-trie/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/15-trie/info.sh)
- Source: [`McCat/15-trie/trie.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/15-trie/trie.c)
- Upstream source says the program may be redistributed and modified if its copyright notice is maintained. The complete retained notice and disclaimer are in [`LICENSE.txt`](LICENSE.txt).

## Workload and implementations

[`workload.json`](workload.json) contains insertion-order, prefix, duplicate, token-character, maximum-word, and malformed-input cases. [`mccat_trie_oracle.py`](../../mccat_trie_oracle.py) independently models the source's continuation and alternative links.

| Language | Source |
| --- | --- |
| C | [`c/m/mccat_trie.c`](../../../c/m/mccat_trie.c) |
| C3 | [`c3/m/mccat_trie.c3`](../../../c3/m/mccat_trie.c3) |
| C++ | [`cpp/m/mccat_trie.cpp`](../../../cpp/m/mccat_trie.cpp) |
| Elisa | [`elisa/m/mccat_trie.elisa`](../../../elisa/m/mccat_trie.elisa) |
| Nim | [`nim/m/mccat_trie.nim`](../../../nim/m/mccat_trie.nim) |
| Odin | [`odin/m/mccat_trie.odin`](../../../odin/m/mccat_trie.odin) |
| Rust | [`rust/m/mccat_trie.rs`](../../../rust/m/mccat_trie.rs) |
| V | [`v/m/mccat_trie.v`](../../../v/m/mccat_trie.v) |
| Zig | [`zig/m/mccat_trie.zig`](../../../zig/m/mccat_trie.zig) |
