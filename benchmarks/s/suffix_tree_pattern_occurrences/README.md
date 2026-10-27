# Compressed suffix-tree pattern occurrences

This profile implements the suffix-tree query described in DOI 422: follow
compressed edge labels while they match the pattern; if the pattern ends on
that path, enumerate all descendant suffix leaves. A mismatch returns no
occurrences. A unique internal terminator is appended during the bounded
per-call tree construction so each text suffix has a leaf, including suffixes
that are prefixes of other suffixes. The pattern alphabet cannot contain that
terminator.

Input is `[n,text[n],m,pattern[m]]`, with `0<=n<=24`, `1<=m<=12`, and ASCII
codes in `[0,127]`. The call builds the compressed tree, executes one query,
then returns `[count,start_0,...]`. Positions are in lexicographic suffix-leaf
order, using the internal terminator as smaller than every ASCII code. This is
a deterministic ordering refinement; the chapter says to enumerate leaves
but does not prescribe a serialization order. Maximum input is 38 words (39
parseable); maximum output is 200 bytes. Invalid input returns `-1`; null or
short output returns `-2` without writes.

The chapter assumes the suffix tree is already available. This bounded
benchmark includes a clean-room insertion/split construction per call, so it
makes no query-only complexity claim. It is algorithmically distinct from
[`suffix_trie`](../suffix_trie/README.md), which searches an uncompressed trie
and returns only membership, and from
[`suffix_array_lcp_search`](../suffix_array_lcp_search/README.md), which uses
LCP-accelerated binary search over suffix order. It does not profile suffix
tree preprocessing alone.

Source: Srinivas Aluru, “Text Indexing,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_422`](https://doi.org/10.1007/978-1-4939-2864-4_422),
suffix-tree pattern-search discussion. The chapter provides no source-code
license. This is a clean-room implementation with no copied code or prose;
see [RIGHTS.md](RIGHTS.md).

Primary oracle: [`suffix_tree_pattern_occurrences_oracle.py`](../../suffix_tree_pattern_occurrences_oracle.py).
Independent direct-match verifier:
[`suffix_tree_pattern_occurrences_verifier_oracle.py`](../../suffix_tree_pattern_occurrences_verifier_oracle.py).

| Language | Port |
|---|---|
| C | `c/s/suffix_tree_pattern_occurrences.c` |
| C3 | `c3/s/suffix_tree_pattern_occurrences.c3` |
| C++ | `cpp/s/suffix_tree_pattern_occurrences.cpp` |
| Elisa | `elisa/s/suffix_tree_pattern_occurrences.elisa` |
| Nim | `nim/s/suffix_tree_pattern_occurrences.nim` |
| Odin | `odin/s/suffix_tree_pattern_occurrences.odin` |
| Rust | `rust/s/suffix_tree_pattern_occurrences.rs` |
| V | `v/s/suffix_tree_pattern_occurrences.v` |
| Zig | `zig/s/suffix_tree_pattern_occurrences.zig` |
