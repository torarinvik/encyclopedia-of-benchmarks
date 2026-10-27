# Compacted-trie ranking for MMPHF delimiters

This package implements the chapter's simple ranking-based distributor
primitive for DOI 639. It builds a compacted binary trie over a sorted set of
fixed-width delimiter keys, then returns the number of delimiters strictly
smaller than each query. This is the chapter's illustrated compacted-trie
ranking approach; it is distinct from [`mmpfh_bucketing`](../mmpfh_bucketing/README.md),
which uses equal-size buckets and explicit `d0`/`d1` mappings.

Input is `[w,d,q,delimiters...,queries...]`, with `1<=w<=16`, `1<=d<=16`,
and `1<=q<=16`. Keys are unsigned integers represented in the low `w` bits;
delimiter keys must be strictly increasing. The trie is built canonically by
splitting each sorted key range at its most significant differing bit. Bit
indices are MSB-first (`0` is bit `w-1`). Node IDs are assigned in preorder,
visiting left before right. Every record is
`[branch_bit,left_id,right_id,subtree_min,subtree_max]`; leaves use
`[-1,-1,-1,key,key]`. Before each branch, a query below the subtree minimum
exits with the rank accumulated so far; a query above the subtree maximum
exits with that rank plus the subtree leaf count. This resolves queries that
diverge in a skipped prefix as well as terminal-leaf ordering. Taking a right
edge adds the number of delimiter leaves in the left subtree. Output is
`[d,node_count,q,node_records...,ranks...]`.

ABI: `i64_array_bytes_output`, symbol `mmpfh_compacted_trie_rank`. Malformed
input returns `-1`; null output or insufficient capacity returns `-2` without
writing. Maximum input is 35 i64 words. A binary Patricia trie with `d`
leaves has `2*d-1` nodes, so the maximum output is `3 + 5*31 + 16 = 174`
i64 words (1,392 bytes). This profile does not implement the succinct
`d0`/`d1` or per-bucket perfect-hash functions and makes no succinct-space,
constant-time, or z-fast-trie claim. The chapter mentions z-fast relative
ranking and correction storage but does not specify its construction or
encoding sufficiently for a source-faithful port here.

The primary oracle builds a sorted-range Patricia trie. The independent
verifier builds a full binary trie and compresses unary paths before assigning
the same canonical preorder IDs.

Source: Paolo Boldi and Sebastiano Vigna, “Monotone Minimal Perfect Hash
Functions,” *Encyclopedia of Algorithms*, DOI
10.1007/978-1-4939-2864-4_639. See [`RIGHTS.md`](RIGHTS.md).

| Language | Port |
|---|---|
| C | `c/m/mmpfh_compacted_trie_rank.c` |
| C3 | `c3/m/mmpfh_compacted_trie_rank.c3` |
| C++ | `cpp/m/mmpfh_compacted_trie_rank.cpp` |
| Elisa | `elisa/m/mmpfh_compacted_trie_rank.elisa` |
| Nim | `nim/m/mmpfh_compacted_trie_rank.nim` |
| Odin | `odin/m/mmpfh_compacted_trie_rank.odin` |
| Rust | `rust/m/mmpfh_compacted_trie_rank.rs` |
| V | `v/m/mmpfh_compacted_trie_rank.v` |
| Zig | `zig/m/mmpfh_compacted_trie_rank.zig` |
