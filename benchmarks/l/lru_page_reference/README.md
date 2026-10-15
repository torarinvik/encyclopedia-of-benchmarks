# LRU page reference

Process a bounded sequence of page references through a least-recently-used cache. Each reference reports whether the page was already resident and which page, if any, was evicted. The final cache is returned from most recently used to least recently used.

## Contract

- Input is packed as `[capacity, reference_count, page_ids...]` in signed 64-bit integers, with exact packing and no trailing fields.
- Capacity is a power of two from 1 through 64. Reference count is 0 through 256. Page IDs are from 0 through 1,000,000; `-1` is reserved to mean that no page was evicted.
- A hit moves the referenced page to MRU and reports `(1, -1)`. A miss reports `(0, evicted_page)`; the page is `-1` when there was free capacity. A miss at full capacity evicts the LRU page before inserting the reference at MRU.
- Output is signed 64-bit integers encoded little-endian: `[reference_count, (hit_flag, evicted_page)*reference_count, final_cache_count, final_cache_MRU_to_LRU...]`. The return value is the output byte count.
- Malformed packing or out-of-domain fields return `-1`; insufficient output capacity or a null output buffer returns `-2`.

## Source variants

The pinned C++ implementation records hit and page-fault counts around its `refer` operation. The C# implementation uses `Get` and `Put` over a linked list, Python's `get`/`put` moves keys through its ordered cache, and Zig's map exposes nodes that are explicitly moved to the front on a hit. This benchmark uses page IDs as both keys and values where the source has values, and standardizes all variants to one record per access. The output's MRU-first order is independent of whether a source keeps MRU at the list head or tail.

- [TheAlgorithms/C-Plus-Plus pinned `lru_cache.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/lru_cache.cpp)
- [TheAlgorithms/C-Plus-Plus-1 pinned mirror `lru_cache.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/others/lru_cache.cpp)
- [TheAlgorithms/C-Sharp pinned `LruCache.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Cache/LruCache.cs)
- [TheAlgorithms/Python pinned `lru_cache.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/lru_cache.py)
- [TheAlgorithms/Zig pinned `lruCache.zig`](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/dataStructures/lruCache.zig)

[`workload.json`](workload.json) covers eviction and reaccess, recency refresh on a hit, a one-slot cache, an empty stream, and invalid capacity/page/packing values. All nine ports use the shared `i64_array_bytes_output` ABI.
