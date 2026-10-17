# Compressed suffix-tree construction

This benchmark covers the pinned Rust `SuffixTree::new` constructor, which builds a compressed suffix tree by inserting each suffix and splitting existing edge labels when prefixes diverge. It is tracked separately from [`suffix_trie`](../suffix_trie/README.md), the Python module with the same source stem that instead builds an uncompressed trie and exposes substring search.

## Contract

The ABI is `i64_array_bytes_output`. Input is `[text_length, text_ascii_codes...]`, with length 0 through 64 and 7-bit ASCII codes in `0..127`. The packed input length must be exactly `1+text_length`. The bounded ASCII domain keeps Rust's byte offsets and character positions aligned, including for NUL.

Construct the compressed suffix tree from every suffix `text[i..]` for `i=0..text_length-1`, without adding a sentinel. Serialize the public `nodes` vector in insertion order as: node count (`u64` little-endian), then for each node its label byte length (`u64` little-endian), label bytes, child count (`u64` little-endian), and child node indices (`u64` little-endian) in their stored order. The root is node zero with an empty label. The output captures the source's compressed labels, edge-split decisions, insertion order, and child order. It does not serialize allocator capacity or Rust object layout.

Each suffix insertion adds at most one split node and one new leaf, so there are at most `1+2*text_length` nodes and `2*text_length` child edges. Splitting an edge preserves its total label length; each newly appended leaf adds at most the length of the suffix being inserted. Therefore total label bytes are at most the sum of all suffix lengths, `text_length*(text_length+1)/2`. Including the node and child-index fields, the serialized output is bounded by `text_length*(text_length+1)/2 + 48*text_length + 24`, at most 5,176 bytes. Malformed framing, unsupported lengths, nonintegral input values, or codes outside `0..127` return `-1` before output checks. A null output or capacity below the serialized size returns `-2` without writes.

## Pinned source

- Rust `SuffixTree::new`, `SuffixTree::add_suffix`, and the `Node` representation: https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/suffix_tree.rs

The source does not add a terminal marker or expose search. The contract therefore measures construction and preserves the exact node vector rather than adding Python's distinct substring-search behavior.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`suffix_tree_oracle.py`](../../suffix_tree_oracle.py)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/s/suffix_tree.c`](../../../c/s/suffix_tree.c) |
| C3 | [`c3/s/suffix_tree.c3`](../../../c3/s/suffix_tree.c3) |
| C++ | [`cpp/s/suffix_tree.cpp`](../../../cpp/s/suffix_tree.cpp) |
| Elisa | [`elisa/s/suffix_tree.elisa`](../../../elisa/s/suffix_tree.elisa) |
| Nim | [`nim/s/suffix_tree.nim`](../../../nim/s/suffix_tree.nim) |
| Odin | [`odin/s/suffix_tree.odin`](../../../odin/s/suffix_tree.odin) |
| Rust | [`rust/s/suffix_tree.rs`](../../../rust/s/suffix_tree.rs) |
| V | [`v/s/suffix_tree.v`](../../../v/s/suffix_tree.v) |
| Zig | [`zig/s/suffix_tree.zig`](../../../zig/s/suffix_tree.zig) |
