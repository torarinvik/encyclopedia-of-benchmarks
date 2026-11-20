# Blind-trie suffix-array construction

This package builds a suffix array by inserting each suffix into an ordered
blind trie, then traversing the trie’s leaves from left to right. A trie node
stores the common-prefix length `k` for its descendant strings; its outgoing
edges are ordered by the symbol at offset `k`. Each leaf stores one suffix
start. During insertion, a blind descent reaches a candidate leaf, a direct
comparison finds the true longest common prefix, and the new branch is spliced
at that prefix. This is the bounded all-suffix profile of blind sorting, not
the full deep-shallow suffix sorter.

## Contract

The `i64_array_bytes_output` input is `[text_length, byte_symbols...]`, with
`0 <= text_length <= 32`, byte values in `0..255`, and exactly
`1 + text_length` signed 64-bit words. Each suffix key is the bytes from its
start through the end, followed by a private terminator smaller than every
byte. The terminator makes prefix ordering explicit, including when the text
contains NUL.

The output is every zero-based suffix start in lexicographic order, encoded as
little-endian signed 64-bit integers. Empty text succeeds with an empty result
and returns `0`. Invalid input returns `-1`; a null output or capacity below
`8 * text_length` returns `-2` without writing. The maximum returned vector is
256 bytes. Fixed algorithm state is bounded to 2,304 bytes, including at most
64 trie nodes, a 64-entry traversal stack, 32-entry child scratch and result
storage, scalar metadata, and bounded frame overhead.

The ports insert starts in ascending text order. A blind search follows only
stored branch positions; if it reaches a leaf from the wrong prefix interval,
the LCP comparison and second descent place the new branch at its correct
ancestor. Ordered edge labels make left-to-right leaf traversal the suffix
array. With at most 32 suffixes, the implementation takes O(n²) worst-case
time and O(n) node storage.

## Distinction and references

Local [`suffix_array`](../suffix_array/README.md) uses rank doubling,
[`suffix_array_dc3`](../suffix_array_dc3/README.md) uses modulo-three sample
sorting, [`suffix_array_sais`](../suffix_array_sais/README.md) uses LMS
induced sorting, [`suffix_array_inplace_readonly_integer`](../suffix_array_inplace_readonly_integer/README.md)
uses a bounded read-only induced-sorting specialization, and
[`suffix_balanced_tree`](../suffix_balanced_tree/README.md) inserts suffixes
into a scapegoat-style tree. This profile instead obtains suffix order by
blind-trie insertion and ordered leaf traversal.

- NIST DADS, [blind sort](https://xlinux.nist.gov/dads/HTML/blindSort.html)
  (discovery and concise method description).
- Manzini and Ferragina, [*Engineering a Lightweight Suffix Array
  Construction Algorithm*](https://doi.org/10.1007/s00453-004-1094-1),
  Section 3.1; see also the [author-hosted ESA 2002 paper](https://people.unipmn.it/manzini/papers/esa02.pdf).

The papers describe blind insertion and ordered leaf traversal within a larger
deep-shallow construction. This package uses that kernel directly on all
bounded suffixes. Only algorithm descriptions informed the clean-room ports,
oracles, fixtures, and documentation; see [`RIGHTS.md`](RIGHTS.md).

The [primary reference](primary_oracle.py) builds the blind trie; the
[independent reference](independent_oracle.py) sorts complete suffix slices.
The [workload](workload.json) covers prefix ordering, equal and periodic
symbols, embedded NUL, high byte values, maximum framing, malformed input, and
output-buffer errors. [`verify_workload.py`](verify_workload.py) statically
checks fixture agreement, provenance, metadata, and all ten source paths; it
has not been run.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/suffix_array_blind_trie.c`](../../../c/s/suffix_array_blind_trie.c) |
| C3 | [`c3/s/suffix_array_blind_trie.c3`](../../../c3/s/suffix_array_blind_trie.c3) |
| C++ | [`cpp/s/suffix_array_blind_trie.cpp`](../../../cpp/s/suffix_array_blind_trie.cpp) |
| Elisa | [`elisa/s/suffix_array_blind_trie.elisa`](../../../elisa/s/suffix_array_blind_trie.elisa) |
| Mojo | [`mojo/s/suffix_array_blind_trie.mojo`](../../../mojo/s/suffix_array_blind_trie.mojo) |
| Nim | [`nim/s/suffix_array_blind_trie.nim`](../../../nim/s/suffix_array_blind_trie.nim) |
| Odin | [`odin/s/suffix_array_blind_trie.odin`](../../../odin/s/suffix_array_blind_trie.odin) |
| Rust | [`rust/s/suffix_array_blind_trie.rs`](../../../rust/s/suffix_array_blind_trie.rs) |
| V | [`v/s/suffix_array_blind_trie.v`](../../../v/s/suffix_array_blind_trie.v) |
| Zig | [`zig/s/suffix_array_blind_trie.zig`](../../../zig/s/suffix_array_blind_trie.zig) |
