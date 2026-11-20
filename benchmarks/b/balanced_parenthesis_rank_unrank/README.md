# Balanced parenthesis rank and unrank

This two-mode profile maps a balanced single-type parenthesis word to its
zero-based lexicographic rank, or reconstructs the word at a supplied rank.
Both operations use dynamic-programming counts of valid suffixes for each
remaining length and current balance.

## Contract

The bounded pair count is `1..10`. Mode 0 input is
`[0,pair_count,symbols...]`, with 0 for `(` and 1 for `)`, and exactly
`2*pair_count` symbols. It returns the zero-based rank with `(` ordered before
`)`. Mode 1 input is `[1,pair_count,rank]`; it returns the word as a fixed-width
`2*pair_count`-bit integer formed by shifting left and appending each symbol.
Leading open symbols are represented by leading zero bits, with the pair count
fixing the width. For three pairs the five words map to codes 7, 11, 13, 19,
and 21 in lexicographic order. Invalid mode, framing, symbol, balance, or rank
returns `-1`. The maximum valid mode-0 input is 22 signed 64-bit values; the
maximum parseable frame is 23 values. The completion table uses 231 signed
64-bit entries at the profile bound.

The primary fills a suffix-completion table and uses it to count lexicographically
smaller branches or select a branch. The independent oracle exhaustively scans
fixed-cardinality open-position sets in lexicographic order. This profile adds
rank and unrank operations beside [`catalan_number`](../../c/catalan_number/README.md),
which only counts the family, and [`parentheses_generator`](../../p/parentheses_generator/README.md),
which emits the entire family recursively. It does not duplicate the separate
single-step [`balanced_parenthesis_successor`](../balanced_parenthesis_successor/README.md).

Source: CP-Algorithms [balanced bracket sequences — sequence index](https://cp-algorithms.com/combinatorics/bracket_sequences.html#sequence-index)
and [k-th sequence](https://cp-algorithms.com/combinatorics/bracket_sequences.html#finding-the-k-th-sequence),
CC BY-SA 4.0. The algorithm description only is used; contract, code, references,
fixtures, and prose are clean-room. See [RIGHTS.md](RIGHTS.md).

## Ports and static inventory

[`verify_workload.py`](verify_workload.py) statically checks the two references,
workload frames, required cases, and all ten exported source paths without
compiling or executing language ports.

| Language | Port |
|---|---|
| C | [`c/b/balanced_parenthesis_rank_unrank.c`](../../../c/balanced_parenthesis_rank_unrank.c) |
| C3 | [`c3/b/balanced_parenthesis_rank_unrank.c3`](../../../c3/b/balanced_parenthesis_rank_unrank.c3) |
| C++ | [`cpp/b/balanced_parenthesis_rank_unrank.cpp`](../../../cpp/b/balanced_parenthesis_rank_unrank.cpp) |
| Elisa | [`elisa/b/balanced_parenthesis_rank_unrank.elisa`](../../../elisa/b/balanced_parenthesis_rank_unrank.elisa) |
| Mojo | [`mojo/b/balanced_parenthesis_rank_unrank.mojo`](../../../mojo/b/balanced_parenthesis_rank_unrank.mojo) |
| Nim | [`nim/b/balanced_parenthesis_rank_unrank.nim`](../../../nim/b/balanced_parenthesis_rank_unrank.nim) |
| Odin | [`odin/b/balanced_parenthesis_rank_unrank.odin`](../../../odin/b/balanced_parenthesis_rank_unrank.odin) |
| Rust | [`rust/b/balanced_parenthesis_rank_unrank.rs`](../../../rust/b/balanced_parenthesis_rank_unrank.rs) |
| V | [`v/b/balanced_parenthesis_rank_unrank.v`](../../../v/b/balanced_parenthesis_rank_unrank.v) |
| Zig | [`zig/b/balanced_parenthesis_rank_unrank.zig`](../../../zig/b/balanced_parenthesis_rank_unrank.zig) |
