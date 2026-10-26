# Landlord file caching

This bounded profile implements the chapter's Landlord algorithm for file
caching with variable file sizes and retrieval costs. A miss first makes
room: reduce every resident file's credit by its size times the smallest
credit-to-size ratio, then evict all files whose credit reaches zero. Insert
the requested file with credit equal to its retrieval cost. Hits leave credit
unchanged, choosing one allowed Landlord hit rule. Evicting every zero-credit
file fixes the source algorithm's permitted zero-credit subset choice.

Input is `[capacity, request_count, (file_id, size, retrieval_cost)*]`, with
capacity 1–8, at most 7 requests, IDs 0–7, sizes 1–4 (never larger than the
cache capacity), and costs 0–20. A file keeps the same size and retrieval cost
whenever it is requested. Output is
`[miss_count, total_retrieval_cost, hit_flags, packed_eviction_masks,
resident_mask]`, encoded as five little-endian signed 64-bit values. Hit flag
bit `i` is 1 when request `i` hits. Byte `i` of `packed_eviction_masks` is the
mask of file IDs evicted by request `i`. `resident_mask` gives the final cache.
Invalid input returns `-1`; null output or capacity below 40 bytes returns
`-2` without writing.

Credits use integer units scaled by 12, the least common multiple of allowed
file sizes. This keeps every proportional reduction exact across the nine
ports. The profile covers the chapter's file-caching Landlord rule; it does
not include the separate hit-reset variants, randomized marking, or
equal-size weighted-caching Greedy Dual specialization.

Source: “Online Paging and Caching,” Neal E. Young, *Encyclopedia of
Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_267`](https://doi.org/10.1007/978-1-4939-2864-4_267).
The chapter is used only to identify Landlord's cache-credit recurrence; this
is clean-room code with no copied book text, figures, or source code.

Primary oracle: [`landlord_file_caching_oracle.py`](../../landlord_file_caching_oracle.py).
Independent verifier: [`landlord_file_caching_verifier_oracle.py`](../../landlord_file_caching_verifier_oracle.py).

| Language | Port |
|---|---|
| C | `c/l/landlord_file_caching.c` |
| C3 | `c3/l/landlord_file_caching.c3` |
| C++ | `cpp/l/landlord_file_caching.cpp` |
| Elisa | `elisa/l/landlord_file_caching.elisa` |
| Nim | `nim/l/landlord_file_caching.nim` |
| Odin | `odin/l/landlord_file_caching.odin` |
| Rust | `rust/l/landlord_file_caching.rs` |
| V | `v/l/landlord_file_caching.v` |
| Zig | `zig/l/landlord_file_caching.zig` |
