# Greedy Dual weighted caching

This profile implements the chapter's Greedy Dual algorithm for weighted
caching, where every file has unit size and retrieval costs vary by file. On a
miss, it reduces all resident credits by the smallest current credit until a
slot is available, evicts all files whose credit reaches zero, then inserts
the requested file with credit equal to its retrieval cost. On a hit, it
resets the credit to that file's retrieval cost, choosing one value allowed by
the chapter's hit rule. The deterministic all-zero eviction rule selects one
of the permitted zero-credit subsets.

Input is `[cache_capacity,request_count,(file_id,retrieval_cost)*]`, with
capacity 1–8, at most seven requests, file IDs 0–7, and costs 0–20 that remain
constant for each file ID. Output is five little-endian signed 64-bit values:
`[miss_count,total_retrieval_cost,hit_flags,packed_eviction_masks,resident_mask]`.
Bit `i` of `hit_flags` records a hit on request `i`; byte `i` of the packed
eviction signature gives the file-ID mask evicted on that request. Invalid
input returns `-1`; null output or capacity below 40 bytes returns `-2`
without writing. The bounded profile does not claim the chapter's competitive
ratio.

This is related to the local [Landlord file-caching profile](../landlord_file_caching/README.md),
which also reduces credits proportionally but permits variable file sizes and
uses the Balance specialization that leaves hit credits unchanged. Greedy
Dual's hit reset changes later victim choices, so this package remains a
separate benchmark. It also differs from page-only LRU, FIFO, and Marking.

Primary oracle: [`greedy_dual_weighted_caching_oracle.py`](../../greedy_dual_weighted_caching_oracle.py).
Independent verifier: [`greedy_dual_weighted_caching_verifier_oracle.py`](../../greedy_dual_weighted_caching_verifier_oracle.py).

Source: “Online Paging and Caching,” Neal E. Young, *Encyclopedia of
Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_267`](https://doi.org/10.1007/978-1-4939-2864-4_267).
The chapter is used only for algorithm attribution and the credit rules; no
book code, prose, or figures were copied.

## Workload and ports

The [workload](workload.json) distinguishes the hit-credit reset from the
Balance rule, and covers zero credits, the maximum request count, malformed
metadata, null buffers, and insufficient capacity.

| Language | Port |
|---|---|
| C | `c/g/greedy_dual_weighted_caching.c` |
| C3 | `c3/g/greedy_dual_weighted_caching.c3` |
| C++ | `cpp/g/greedy_dual_weighted_caching.cpp` |
| Elisa | `elisa/g/greedy_dual_weighted_caching.elisa` |
| Nim | `nim/g/greedy_dual_weighted_caching.nim` |
| Odin | `odin/g/greedy_dual_weighted_caching.odin` |
| Rust | `rust/g/greedy_dual_weighted_caching.rs` |
| V | `v/g/greedy_dual_weighted_caching.v` |
| Zig | `zig/g/greedy_dual_weighted_caching.zig` |
