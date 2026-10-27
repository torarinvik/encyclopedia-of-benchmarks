# Bottom-k MinHash sketch

This package profiles DOI 573's bottom-k order-statistic structure. A single
supplied rank assignment is applied to each item; the sketch retains the `k`
items having the smallest ranks, without replacement. On insertion, a new
item fills an available slot, or replaces the current maximum-rank item only
when its `(rank, item_id)` key is smaller. The bounded profile sorts equal
ranks by item ID as a deterministic refinement of the chapter's strict-rank
notation.

Input is `[n,k,(item_id,rank)[n]]`, with `1<=n<=16`, `1<=k<=8`, unique IDs in
`[0,16)`, and supplied ranks in `[0,1000]`. Output is
`[count,item_id,rank,...]` in increasing `(rank,item_id)` order, where
`count=min(n,k)`. Values are serialized as little-endian signed 64-bit
integers. The valid input maximum is 34 words (35 parseable); output maximum
is 136 bytes. Invalid input returns `-1`; null output or insufficient capacity
returns `-2` without writes.

This is an explicit-rank profile of the bottom-k order statistic and threshold
update behavior. It omits hash generation, coordinated random-rank guarantees,
cardinality/similarity estimators, and the chapter's other k-mins and
k-partition sketch variants. The ranks are fixture inputs, not random samples.

Source: Edith Cohen, “Min-Hash Sketches,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_573`](https://doi.org/10.1007/978-1-4939-2864-4_573),
sections “Structure” and “Inserting an Element.” The chapter gives no source
code license. Ports and oracles are clean-room implementations; no book prose
or code is copied. See [RIGHTS.md](RIGHTS.md) and [workload.json](workload.json).

| Language | Port |
|---|---|
| C | `c/m/min_hash_bottom_k.c` |
| C3 | `c3/m/min_hash_bottom_k.c3` |
| C++ | `cpp/m/min_hash_bottom_k.cpp` |
| Elisa | `elisa/m/min_hash_bottom_k.elisa` |
| Nim | `nim/m/min_hash_bottom_k.nim` |
| Odin | `odin/m/min_hash_bottom_k.odin` |
| Rust | `rust/m/min_hash_bottom_k.rs` |
| V | `v/m/min_hash_bottom_k.v` |
| Zig | `zig/m/min_hash_bottom_k.zig` |
