# LRU cache operation trace

Process a bounded sequence of cache puts and gets using the pinned Java and JavaScript LRU cache APIs.

## Contract

- Input is packed as `[capacity, operation_count, (opcode, key, value)*]` in signed 64-bit integers, with exact packing and no trailing fields.
- Capacity is 2 through 16. Operation count is 0 through 32. Opcode `0` inserts a key/value pair; opcode `1` reads a resident key. Keys are 0 through 1,000,000 and values are 0 through 1,000,000. A get's value field must be zero.
- Put keys must be distinct across the trace. Get keys must be resident at the point of the get. These restrictions avoid the JavaScript source's full-cache overwrite behavior and make every get a hit in both sources.
- A put inserts at MRU. If the cache is full, it evicts the LRU key first. A get returns the cached value and moves that key to MRU. The final cache is emitted from MRU to LRU.
- Output is signed 64-bit integers encoded little-endian: `[operation_count, (opcode, returned_value, evicted_key)*, final_count, (key, value)*]`. The returned-value field is `-1` for a put/set because those source operations are void; its evicted key is `-1` when the cache had free space. A get returns its cached value and reports evicted key `-1`.
- Malformed packing or out-of-domain operations return `-1`. A null output buffer or insufficient output capacity returns `-2` after input validation. Errors write no bytes.

## Source behavior

The pinned Java `LRUCache` exposes `put` and `get`, keeps the least-recently-used entry at its list head, and moves a successful get to the tail. The pinned JavaScript `LRUCache` exposes `set` and `get`, stores entries in insertion order, and refreshes a hit by deleting and reinserting the key. Both evict the oldest entry for a new key at capacity. Java's capacity-one eviction path dereferences a null new head, so the shared contract starts at capacity two. The JavaScript setter also evicts before setting even when a key already exists, so repeated puts are excluded.

- [TheAlgorithms/Java pinned `LRUCache.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/caches/LRUCache.java)
- [TheAlgorithms/JavaScript pinned `LRUCache.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Cache/LRUCache.js)

The fixed-workspace ports use the shared `i64_array_bytes_output` ABI. The maximum result is 130 signed 64-bit words (1,040 bytes).
