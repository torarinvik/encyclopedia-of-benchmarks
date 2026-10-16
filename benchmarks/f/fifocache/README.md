# FIFO cache

This benchmark follows the pinned Java `FIFOCache` with its default TTL of zero and the default immediate-expiration strategy. Since zero-TTL entries never expire, the bounded trace exposes the cache's FIFO policy without wall-clock timing. It includes sequential `put` and `get` operations; overwriting a key removes it from its old position and inserts it at the tail. Reads do not change order. Threading, callbacks, TTLs, removal, and builder configuration are outside the shared trace.

Input is `[capacity, operation_count, (opcode, key, value)...]`. Capacity is 1–6, there are at most eight operations, keys are 0–15, and values are 0–255. Opcode 0 inserts/overwrites; opcode 1 gets a key and requires value 0. Invalid input returns -1. The output bytes are `[hit_count, miss_count, final_size, get_count, get_results..., final_key_value_pairs_in_FIFO_order...]`; a missed get is encoded as 255. Success returns the byte count; insufficient or null output returns -2.

The runtime oracle is [`fifocache_oracle.py`](../../fifocache_oracle.py), and workload fixtures are in [`workload.json`](workload.json). FIFO eviction makes this contract distinct from the existing LRU page cache: reads leave insertion order unchanged, and a write to an existing key moves it to the newest position.

Pinned source: [TheAlgorithms/Java `FIFOCache.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/caches/FIFOCache.java).

| Language | Port |
|---|---|
| C | [`c/f/fifocache.c`](../../../c/f/fifocache.c) |
| C3 | [`c3/f/fifocache.c3`](../../../c3/f/fifocache.c3) |
| C++ | [`cpp/f/fifocache.cpp`](../../../cpp/f/fifocache.cpp) |
| Elisa | [`elisa/f/fifocache.elisa`](../../../elisa/f/fifocache.elisa) |
| Nim | [`nim/f/fifocache.nim`](../../../nim/f/fifocache.nim) |
| Odin | [`odin/f/fifocache.odin`](../../../odin/f/fifocache.odin) |
| Rust | [`rust/f/fifocache.rs`](../../../rust/f/fifocache.rs) |
| V | [`v/f/fifocache.v`](../../../v/f/fifocache.v) |
| Zig | [`zig/f/fifocache.zig`](../../../zig/f/fifocache.zig) |

Run the integrated verifier with `python3 benchmarks/verify_i64_array_bytes_output.py --algorithm fifocache --elisa-compiler ../Elisa-compiler/bin/elisac-stage1 --jobs 4`.
