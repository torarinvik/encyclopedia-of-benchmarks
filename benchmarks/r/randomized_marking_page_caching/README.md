# Randomized Marking for Page Caching

This bounded profile implements the chapter's randomized Marking policy for
unit-size, unit-cost pages. A resident page is marked when requested. On a
full-cache miss, the policy evicts one uniformly selected unmarked page. If
every resident is marked, it clears the phase marks first and then chooses a
victim uniformly from the entire resident cache.

## Contract

The ABI is `i64_array_bytes_output`. Input is
`[cache_size,request_count,requests[request_count],choice_count,choice_indices[choice_count]]`.
The cache size is 1–8, there are at most 32 requests, and page IDs are in
`0..15`. The cache begins empty. Each supplied choice index is consumed only
when a full-cache miss evicts a page. At that event, the eligible pages are
the current unmarked residents, in ascending page-ID order; if all pages are
marked, marks are cleared and the whole resident cache becomes eligible. A
choice index selects one page uniformly from this current eligible set when
the supplied indices are sampled uniformly. The input must provide exactly
one index per eviction, and each index must be within the event's eligible
set. Thus a supplied choice tape makes an individual randomized trace
deterministic without changing the policy's choice space.

Output is `[miss_count,final_resident_mask,final_marked_mask,hit_flags[q],victim_ids[q]]`
as little-endian signed 64-bit words. A hit flag is 1 for a hit and 0 for a
miss; a victim ID is `-1` when the request caused no eviction. Masks use bit
`page_id`. The maximum output is 536 bytes. Malformed input or an invalid,
missing, or unused choice returns `-1`; null output or insufficient capacity
returns `-2` without writes.

The primary oracle uses page-indexed residency and mark arrays. The independent
verifier stores residents in a list and tracks the current marked set. Workload
cases cover all-marked phase reset, a later choice among multiple unmarked
residents, hits, empty and maximum-length traces, invalid choice tapes, null
buffers, and capacity failure.

The package covers Marking only. It does not implement the chapter's
Frequency Count, Timestamp, Bit, Comb, weighted-caching Greedy Dual, or
randomized optimal-paging profiles. The local [Landlord profile](../l/landlord_file_caching/README.md),
[LRU profile](../l/lru_page_reference/README.md), and [FIFO profile](../f/fifocache/README.md)
have distinct rules.

Source: Neal E. Young, “Online Paging and Caching,” *Encyclopedia of
Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_267`](https://doi.org/10.1007/978-1-4939-2864-4_267).
The chapter is used only to identify the algorithm; these are clean-room
implementations with no copied book code or prose.

See [workload.json](workload.json), [RIGHTS.md](RIGHTS.md), the
[primary oracle](../../randomized_marking_page_caching_oracle.py), and the
[independent verifier](../../randomized_marking_page_caching_verifier_oracle.py).

| Language | Port |
|---|---|
| C | [`c/r/randomized_marking_page_caching.c`](../../../c/r/randomized_marking_page_caching.c) |
| C3 | [`c3/r/randomized_marking_page_caching.c3`](../../../c3/r/randomized_marking_page_caching.c3) |
| C++ | [`cpp/r/randomized_marking_page_caching.cpp`](../../../cpp/r/randomized_marking_page_caching.cpp) |
| Elisa | [`elisa/r/randomized_marking_page_caching.elisa`](../../../elisa/r/randomized_marking_page_caching.elisa) |
| Nim | [`nim/r/randomized_marking_page_caching.nim`](../../../nim/r/randomized_marking_page_caching.nim) |
| Odin | [`odin/r/randomized_marking_page_caching.odin`](../../../odin/r/randomized_marking_page_caching.odin) |
| Rust | [`rust/r/randomized_marking_page_caching.rs`](../../../rust/r/randomized_marking_page_caching.rs) |
| V | [`v/r/randomized_marking_page_caching.v`](../../../v/r/randomized_marking_page_caching.v) |
| Zig | [`zig/r/randomized_marking_page_caching.zig`](../../../zig/r/randomized_marking_page_caching.zig) |
