# LIFO cache operation trace

This benchmark follows the pinned Java `LIFOCache` with its default configuration. It models a fixed-capacity cache whose insertion order is oldest to youngest: a new key added to a full cache evicts the youngest key. Updating an existing key moves it to the youngest position. Reads do not change insertion order; only reads affect hit and miss counters. Removing a key does not affect those counters, and `clear` resets both the entries and counters.

The Java class supports custom TTLs, eviction strategies, listeners, and concurrent use. This contract uses the default TTL of zero and a bounded sequential trace, so expiration, custom strategies, callbacks, and concurrency are outside the benchmark.

## Contract

Input is `[capacity, operation_count, (opcode, key, value)*]`. Capacity is 1–16 and operation count is 1–64. Keys and values are signed 32-bit integers. Opcodes are `0=put`, `1=get`, `2=removeKey`, `3=size`, `4=getHits`, `5=getMisses`, and `6=clear`; unused operation fields must be zero.

Each operation emits two little-endian signed 64-bit values. Put and clear emit `[1, 0]`; get and remove emit `[present, value-or-zero]`; size and the counters emit `[count, 0]`. The function returns the number of output elements. Invalid input returns `-1`; a null or undersized output buffer returns `-2` without writing.

See [workload](workload.json), [oracle](../../lifocache_oracle.py), and the pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/caches/LIFOCache.java).

| Language | Port |
|---|---|
| C | [c/l/lifocache.c](../../../c/l/lifocache.c) |
| C3 | [c3/l/lifocache.c3](../../../c3/l/lifocache.c3) |
| C++ | [cpp/l/lifocache.cpp](../../../cpp/l/lifocache.cpp) |
| Elisa | [elisa/l/lifocache.elisa](../../../elisa/l/lifocache.elisa) |
| Nim | [nim/l/lifocache.nim](../../../nim/l/lifocache.nim) |
| Odin | [odin/l/lifocache.odin](../../../odin/l/lifocache.odin) |
| Rust | [rust/l/lifocache.rs](../../../rust/l/lifocache.rs) |
| V | [v/l/lifocache.v](../../../v/l/lifocache.v) |
| Zig | [zig/l/lifocache.zig](../../../zig/l/lifocache.zig) |
