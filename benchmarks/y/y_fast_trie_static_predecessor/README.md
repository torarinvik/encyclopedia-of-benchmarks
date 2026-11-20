# Static y-fast trie predecessor and successor queries

This bounded static-set profile partitions sorted keys into clusters of at most
16 values. A binary x-fast trie over cluster maxima selects the candidate
cluster; a sorted array inside the cluster answers strict predecessor and
successor queries. This keeps the y-fast separation between a compact top-level
representative index and small ordered clusters while making the fixed-width
profile deterministic.

## Contract

The exported scalar symbol is `y_fast_trie_static_predecessor`. Input is
`[N,Q,key[0..N),query[0..Q)]`, with `0<=N,Q<=256`, distinct keys, and all keys
and queries in `[0,65535]`. Exact input length is `2+N+Q`; the maximum valid
length is 514 and the maximum parseable length is 515. Malformed input returns
`-1`.

For each query, return the greatest key strictly less than the query and the
least key strictly greater than the query. An exact hit is excluded from both
answers. A missing neighbor is represented by `-1`. The result is
`sum((query_index+1)*((predecessor+1)+65537*(successor+1)))`; a missing
neighbor contributes zero. An empty key set and a zero-query batch return zero
when the frame is otherwise valid.

## Algorithm and profile

Keys are sorted and divided into consecutive clusters of at most 16. Each
cluster maximum is inserted into a 16-bit, most-significant-bit-first binary
trie. Trie nodes retain the smallest cluster rank in their subtree, allowing
one bit walk to choose the first cluster maximum at least as large as a query.
If no such maximum exists, the final cluster is selected. Two binary searches
inside the cluster produce strict neighbors, with a boundary lookup in an
adjacent cluster when needed.

The language ports use insertion sort, so preprocessing costs
`O(N² + 16 ceil(N/16))` time and `O(N + 16 ceil(N/16))` space in this bounded
representation. Each query costs `O(16 + log 16)` worst-case work.
This profile walks the fixed 16-bit trie explicitly and uses deterministic
clusters; it does not claim the classic expected `O(log log U)` query bound of
randomized y-fast trie variants.

## Provenance and rights

The algorithm family is described by Dan E. Willard, “Log-logarithmic
worst-case range queries are possible in space Θ(N),” *Information Processing
Letters* 17(2), 1983, DOI
[10.1016/0020-0190(83)90075-3](https://doi.org/10.1016/0020-0190(83)90075-3).
The source is used for the algorithm idea and attribution only. The bounded
contract, workload, oracles, and implementations are independently authored;
no source code or prose is reused. See [`RIGHTS.md`](RIGHTS.md),
[`workload.json`](workload.json), the
[trie-based primary oracle](../../y_fast_trie_static_predecessor_oracle.py),
the [sorted-array verifier](../../y_fast_trie_static_predecessor_verifier_oracle.py),
and [static package checker](../../check_y_fast_trie_static_predecessor_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/y/y_fast_trie_static_predecessor.c`](../../../c/y/y_fast_trie_static_predecessor.c) |
| C3 | [`c3/y/y_fast_trie_static_predecessor.c3`](../../../c3/y/y_fast_trie_static_predecessor.c3) |
| C++ | [`cpp/y/y_fast_trie_static_predecessor.cpp`](../../../cpp/y/y_fast_trie_static_predecessor.cpp) |
| Elisa | [`elisa/y/y_fast_trie_static_predecessor.elisa`](../../../elisa/y/y_fast_trie_static_predecessor.elisa) |
| Mojo | [`mojo/y/y_fast_trie_static_predecessor.mojo`](../../../mojo/y/y_fast_trie_static_predecessor.mojo) |
| Nim | [`nim/y/y_fast_trie_static_predecessor.nim`](../../../nim/y/y_fast_trie_static_predecessor.nim) |
| Odin | [`odin/y/y_fast_trie_static_predecessor.odin`](../../../odin/y/y_fast_trie_static_predecessor.odin) |
| Rust | [`rust/y/y_fast_trie_static_predecessor.rs`](../../../rust/y/y_fast_trie_static_predecessor.rs) |
| V | [`v/y/y_fast_trie_static_predecessor.v`](../../../v/y/y_fast_trie_static_predecessor.v) |
| Zig | [`zig/y/y_fast_trie_static_predecessor.zig`](../../../zig/y/y_fast_trie_static_predecessor.zig) |
