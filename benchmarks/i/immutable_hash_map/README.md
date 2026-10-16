# Immutable Hash Map

This package ports the pinned Java persistent hash map for signed 32-bit keys and values. Each `put` returns a new map with a new head entry and increments size, including when the key already exists. The benchmark continues with that returned map, so later lookups see the newest value for a duplicate key.

## Contract

- The `i64_array_scalar` input is `[n, (operation, key, value)*n]` with exact length `1 + 3*n` and `0 <= n <= 256`.
- Operations are `0=put`, `1=get`, `2=containsKey`, and `3=size`. Every key and value slot must fit signed 32-bit. A `put` value must be nonzero; the value slot for other operations is validated but ignored.
- The map starts empty. `put` appends a key/value pair to the current persistent version, even for duplicate keys. `get` returns the newest value or zero when absent; `containsKey` returns one or zero; `size` returns the current entry count.
- Invalid operation, malformed length, out-of-range key/value, or a zero `put` value returns `-1`.
- The trace has one signed integer per operation. The scalar result is the low 63 bits of FNV-1a-64 over `[n, trace_0, ..., trace_(n-1)]` encoded as signed-i64 little-endian words. The offset basis is `14695981039346656037` and the prime is `1099511628211`.

The [independent oracle](../../immutable_hash_map_oracle.py) keeps a newest-first search history, while the language ports use fixed-size key/value histories. The [workload](workload.json) covers persistence across puts, duplicate-key shadowing, absent lookups, all operations, hash collisions, signed boundaries, and invalid inputs.

## Upstream source

- [TheAlgorithms/Java `ImmutableHashMap.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/hashmap/hashing/ImmutableHashMap.java)

| Language | Port |
|---|---|
| C | [`c/i/immutable_hash_map.c`](../../../c/i/immutable_hash_map.c) |
| C3 | [`c3/i/immutable_hash_map.c3`](../../../c3/i/immutable_hash_map.c3) |
| C++ | [`cpp/i/immutable_hash_map.cpp`](../../../cpp/i/immutable_hash_map.cpp) |
| Elisa | [`elisa/i/immutable_hash_map.elisa`](../../../elisa/i/immutable_hash_map.elisa) |
| Nim | [`nim/i/immutable_hash_map.nim`](../../../nim/i/immutable_hash_map.nim) |
| Odin | [`odin/i/immutable_hash_map.odin`](../../../odin/i/immutable_hash_map.odin) |
| Rust | [`rust/i/immutable_hash_map.rs`](../../../rust/i/immutable_hash_map.rs) |
| V | [`v/i/immutable_hash_map.v`](../../../v/i/immutable_hash_map.v) |
| Zig | [`zig/i/immutable_hash_map.zig`](../../../zig/i/immutable_hash_map.zig) |
