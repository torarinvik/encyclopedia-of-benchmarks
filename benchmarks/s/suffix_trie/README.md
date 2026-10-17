# Suffix-trie search

This benchmark selects the `SuffixTree` construction and `search` behavior from the pinned Python source. Despite the upstream class and module name, that implementation inserts every suffix into an uncompressed character trie and reports whether a query follows a path in the trie. As a result, the observable search operation is substring membership; it does not require the query to end at a suffix terminator. The empty query matches, including when the indexed text is empty.

## Contract

The ABI is `i64_array_scalar`. Input is `[text_length, pattern_length, text_ascii_codes..., pattern_ascii_codes...]`. Text length is 0 through 64, pattern length is 0 through 16, and each code is a 7-bit ASCII code in `0..127`. The packed input length must be exactly `2+text_length+pattern_length`. The bounded alphabet keeps Python character positions identical to the byte positions in each port.

Construct the source's suffix trie by inserting every suffix `text[i:]`, for starts `i=0..text_length-1`, then search from its root by following each pattern code. Return 1 when all pattern codes follow child links and 0 otherwise. An empty pattern returns 1 because the search loop consumes no characters; a nonempty pattern against empty text returns 0. The contract includes construction and one search per call. The maximum source trie has at most `1 + text_length*(text_length+1)/2` nodes.

Malformed framing, unsupported lengths, nonintegral input values, or codes outside `0..127` return `-1`. Output is one signed 64-bit Boolean scalar: 1 for found and 0 for absent.

## Pinned source

- Python `SuffixTree.__init__`, `build_suffix_tree`, `_add_suffix`, and `search`: https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/suffix_tree/suffix_tree.py

The separate Rust source constructs a compressed suffix tree and has no matching search API, so this workload pins the Python source's observable constructor-plus-search operation. Node metadata (`is_end_of_string`, `start`, and `end`) is not consulted by `search` and is outside the output contract.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`suffix_trie_oracle.py`](../../suffix_trie_oracle.py)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/s/suffix_trie.c`](../../../c/s/suffix_trie.c) |
| C3 | [`c3/s/suffix_trie.c3`](../../../c3/s/suffix_trie.c3) |
| C++ | [`cpp/s/suffix_trie.cpp`](../../../cpp/s/suffix_trie.cpp) |
| Elisa | [`elisa/s/suffix_trie.elisa`](../../../elisa/s/suffix_trie.elisa) |
| Nim | [`nim/s/suffix_trie.nim`](../../../nim/s/suffix_trie.nim) |
| Odin | [`odin/s/suffix_trie.odin`](../../../odin/s/suffix_trie.odin) |
| Rust | [`rust/s/suffix_trie.rs`](../../../rust/s/suffix_trie.rs) |
| V | [`v/s/suffix_trie.v`](../../../v/s/suffix_trie.v) |
| Zig | [`zig/s/suffix_trie.zig`](../../../zig/s/suffix_trie.zig) |
