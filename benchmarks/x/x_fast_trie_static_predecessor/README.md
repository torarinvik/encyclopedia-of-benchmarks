# Static x-fast trie predecessor queries

This package profiles integer predecessor search with a static x-fast trie
index. Each trie level stores the distinct prefixes represented by the key set.
For a query, the implementation binary-searches the levels to find its longest
represented prefix, then climbs toward the root until it finds a represented
left sibling; that sibling's maximum key is the predecessor. Prefix catalogs
are stored as sorted fixed arrays in this bounded profile, so it does not claim
the original expected `O(log log U)` query bound for hash-backed x-fast tries.

## Contract

The exported scalar symbol is `x_fast_trie_static_predecessor`. Input is
`[N,Q,key[0..N),query[0..Q)]`, with `0<=N,Q<=24`, unique keys in
`[0,65535]`, and queries in `[0,65535]`. The exact length is `2+N+Q`; the
maximum valid input is 50 i64 values and the maximum parseable input is 51.
Malformed input returns `-1`.

For each query, the predecessor is the greatest stored key no larger than the
query. An exact hit returns that key; if no key is small enough, the query's
predecessor is `-1`. The scalar result is
`sum((query_index+1)*(predecessor+1))` over zero-based query indices. Thus a
missing predecessor contributes zero. An empty key set returns zero for any
valid query batch, and a zero-query batch returns zero after validating its
keys.

The primary uses per-prefix x-fast level catalogs and longest-prefix search.
The independent oracle sorts keys and answers each query with an upper-bound
search. Building catalogs takes `O(16N)` time and space. The bounded primary
uses `O(16 log N)` work per query in the worst case because catalogs use
deterministic binary search rather than hash tables.

## Provenance and rights

The selected structure is the x-fast trie variant in the predecessor-search
family surveyed by Djamal Belazzougui, “Predecessor Search, String Algorithms
and Data Structures,” *Encyclopedia of Algorithms*, DOI
[10.1007/978-1-4939-2864-4_632](https://doi.org/10.1007/978-1-4939-2864-4_632).
The chapter cites Willard's x-fast/y-fast trie work. The chapter is copyrighted
by Springer; this package uses algorithm names and high-level descriptions
only. Implementations, bounded contract, fixtures, and oracles are clean-room
work. See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the
[primary oracle](../../x_fast_trie_static_predecessor_oracle.py), the
[independent verifier](../../x_fast_trie_static_predecessor_verifier_oracle.py),
and the [static inventory checker](../../check_x_fast_trie_static_predecessor_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/x/x_fast_trie_static_predecessor.c`](../../../c/x/x_fast_trie_static_predecessor.c) |
| C3 | [`c3/x/x_fast_trie_static_predecessor.c3`](../../../c3/x/x_fast_trie_static_predecessor.c3) |
| C++ | [`cpp/x/x_fast_trie_static_predecessor.cpp`](../../../cpp/x/x_fast_trie_static_predecessor.cpp) |
| Elisa | [`elisa/x/x_fast_trie_static_predecessor.elisa`](../../../elisa/x/x_fast_trie_static_predecessor.elisa) |
| Mojo | [`mojo/x/x_fast_trie_static_predecessor.mojo`](../../../mojo/x/x_fast_trie_static_predecessor.mojo) |
| Nim | [`nim/x/x_fast_trie_static_predecessor.nim`](../../../nim/x/x_fast_trie_static_predecessor.nim) |
| Odin | [`odin/x/x_fast_trie_static_predecessor.odin`](../../../odin/x/x_fast_trie_static_predecessor.odin) |
| Rust | [`rust/x/x_fast_trie_static_predecessor.rs`](../../../rust/x/x_fast_trie_static_predecessor.rs) |
| V | [`v/x/x_fast_trie_static_predecessor.v`](../../../v/x/x_fast_trie_static_predecessor.v) |
| Zig | [`zig/x/x_fast_trie_static_predecessor.zig`](../../../zig/x/x_fast_trie_static_predecessor.zig) |
