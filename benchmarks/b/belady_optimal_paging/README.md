# Belady optimal paging

Replay an offline page-reference sequence and minimize page faults by evicting
the resident page whose next request is farthest in the known future.

## Contract

Input is `[capacity, request_count, page_ids...]`, with cache capacity `1..8`,
at most 64 requests, and page IDs in `0..15`. A page fault occurs when the
requested page is absent. If the cache is full, evict the resident page whose
next use has the largest request index; a page never used again is considered
to have infinite next-use distance. Ties between equally distant pages evict
the smallest page ID.

The scalar result is `faults * 33281 + eviction_checksum`, where the checksum
adds `(one_based_request_position * (evicted_page_id + 1))` for each eviction.
The checksum's maximum is 33,280, so the fault count remains the leading
field. Invalid frames return `-1`.

The primary uses a reverse-built next-use table and scans the at-most-16
resident IDs on each full-cache miss. The independent verifier scans the
remaining request suffix directly for each resident page. With at most `N`
requests and `P=16` possible pages, the bounded primary uses `O(NP + N*P)`
time and `O(NP)` auxiliary space; the direct-scan reference uses
`O(N^2*P)` time. The output records both the fault count and a deterministic
eviction checksum.

This differs from recency-based LRU/MRU and arrival-order FIFO policies.
Belady's rule uses future requests and defines the optimum fault count for the
supplied trace. See [`workload.json`](workload.json) and
[`RIGHTS.md`](RIGHTS.md) for the bounded profile and source attribution.

| Language | Source |
|---|---|
| C | [`c/b/belady_optimal_paging.c`](../../../c/b/belady_optimal_paging.c) |
| C3 | [`c3/b/belady_optimal_paging.c3`](../../../c3/b/belady_optimal_paging.c3) |
| C++ | [`cpp/b/belady_optimal_paging.cpp`](../../../cpp/b/belady_optimal_paging.cpp) |
| Elisa | [`elisa/b/belady_optimal_paging.elisa`](../../../elisa/b/belady_optimal_paging.elisa) |
| Mojo | [`mojo/b/belady_optimal_paging.mojo`](../../../mojo/b/belady_optimal_paging.mojo) |
| Nim | [`nim/b/belady_optimal_paging.nim`](../../../nim/b/belady_optimal_paging.nim) |
| Odin | [`odin/b/belady_optimal_paging.odin`](../../../odin/b/belady_optimal_paging.odin) |
| Rust | [`rust/b/belady_optimal_paging.rs`](../../../rust/b/belady_optimal_paging.rs) |
| V | [`v/b/belady_optimal_paging.v`](../../../v/b/belady_optimal_paging.v) |
| Zig | [`zig/b/belady_optimal_paging.zig`](../../../zig/b/belady_optimal_paging.zig) |
