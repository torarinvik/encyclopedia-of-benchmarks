# k-partition MinHash sketch

This package profiles DOI 573's `k`-partition (stochastic-averaging) sketch.
One supplied bucket assignment and one supplied rank are used per stream
item. Each bucket retains the item with the smallest rank. Equal ranks use the
lower stream-position item ID as a deterministic refinement.

Input is `[k,n,(bucket,rank)[n]]`, with `1<=k<=8`, `0<=n<=32`, bucket IDs in
`[0,k)`, and supplied ranks in `[0,1000]`. Item ID is the zero-based stream
position. Output contains `(item_id,rank)` for every bucket in ascending bucket
order. An empty bucket is `(-1,1001)`, where 1001 is the rank-domain sentinel.
The stream is an explicit deterministic realization of the bucket and rank
choices; the benchmark does not generate hashes or claim the chapter's
probabilistic estimator properties.

ABI: `i64_array_bytes_output`, symbol `min_hash_k_partition`. Malformed input
returns `-1`; null output or capacity below `16*k` returns `-2` without
writing. Maximum input is 66 i64 words. Maximum output is 16 i64 words (128
bytes). The primary oracle models streaming bucket updates; the independent
verifier selects each bucket's minimum from the complete item set.

This is distinct from [`min_hash_k_mins`](../min_hash_k_mins/README.md), which
uses `k` independent rank assignments and samples with replacement, and from
[`min_hash_bottom_k`](../min_hash_bottom_k/README.md), which stores the global
`k` smallest ranks without replacement. The chapter's rank/bucket hash laws
and cardinality/similarity estimator guarantees are outside this supplied-tape
profile.

Source: Edith Cohen, “Min-Hash Sketches,” *Encyclopedia of Algorithms*, DOI
10.1007/978-1-4939-2864-4_573. See [`RIGHTS.md`](RIGHTS.md).

| Language | Port |
|---|---|
| C | `c/m/min_hash_k_partition.c` |
| C3 | `c3/m/min_hash_k_partition.c3` |
| C++ | `cpp/m/min_hash_k_partition.cpp` |
| Elisa | `elisa/m/min_hash_k_partition.elisa` |
| Nim | `nim/m/min_hash_k_partition.nim` |
| Odin | `odin/m/min_hash_k_partition.odin` |
| Rust | `rust/m/min_hash_k_partition.rs` |
| V | `v/m/min_hash_k_partition.v` |
| Zig | `zig/m/min_hash_k_partition.zig` |
