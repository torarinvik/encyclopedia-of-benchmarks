# MRU cache

This package benchmarks the pinned Java `MRUCache<Integer, Integer>` with a
bounded deterministic operation trace. It preserves the source's linked-list
order: the tail is the most recently used entry, and inserting a new key into
a full cache evicts that tail entry.

## Contract

The `i64_array_scalar` input is `[capacity, q, (op, key, value)*q]` with exact
length `2 + 3*q`. Capacity is 1..16 and `q` is 0..128. Keys fit signed 32-bit;
put values are 0..1,000,000. For both operations the value field must fit
signed 32-bit; a `get` value field is ignored.

- `op=0` puts a key/value pair. An existing key is updated and moved to the
  MRU tail. A new key is appended to the tail when space is available. When the
  cache is full, the existing MRU tail is removed before the new entry is
  appended.
- `op=1` gets a key. A hit returns its value and moves it to the MRU tail. A
  miss returns the sentinel `-1` and leaves the order unchanged.

The scalar result is the low 63 bits of FNV-1a-64 over the number of `get`
responses as a two-byte little-endian unsigned integer, followed by each
response in call order as a signed 32-bit little-endian two's-complement
integer. The FNV offset basis is `14695981039346656037` and the prime is
`1099511628211`. Invalid operation codes, malformed lengths, or values outside
the stated ranges return `-1`.

The [independent oracle](../../mrucache_oracle.py) uses a map plus an oldest-to-
newest key list. The [workload](workload.json) covers updates, hit promotion,
miss stability, MRU eviction, capacity one, signed keys, and malformed inputs.

## Upstream source

- [TheAlgorithms/Java `MRUCache.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/caches/MRUCache.java)

| Language | Port |
|---|---|
| C | [`c/m/mrucache.c`](../../../c/m/mrucache.c) |
| C3 | [`c3/m/mrucache.c3`](../../../c3/m/mrucache.c3) |
| C++ | [`cpp/m/mrucache.cpp`](../../../cpp/m/mrucache.cpp) |
| Elisa | [`elisa/m/mrucache.elisa`](../../../elisa/m/mrucache.elisa) |
| Nim | [`nim/m/mrucache.nim`](../../../nim/m/mrucache.nim) |
| Odin | [`odin/m/mrucache.odin`](../../../odin/m/mrucache.odin) |
| Rust | [`rust/m/mrucache.rs`](../../../rust/m/mrucache.rs) |
| V | [`v/m/mrucache.v`](../../../v/m/mrucache.v) |
| Zig | [`zig/m/mrucache.zig`](../../../zig/m/mrucache.zig) |
