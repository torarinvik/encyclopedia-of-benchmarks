# Generic hash map operation trace

## Contract

The pinned Java candidates `GenericHashMapUsingArray` and `GenericHashMapUsingArrayList` are both generic maps implemented with separate chaining in lists. They insert or update a key/value pair, retrieve a value, remove a key if present, and expose map size; the ArrayList version also exposes `containsKey`. A put for an existing key updates its value, removal of an absent key is a no-op, and neither implementation uses tombstones.

The shared signed 64-bit input is `[operation_count, (opcode, key, value)*]`, with up to 128 operations, at most 64 distinct keys, keys in `0..1,000,000`, and values in `-1,000,000..1,000,000`. Opcodes are `0` put/update, `1` get, `2` remove, `3` contains, and `4` size. Get, remove, and contains require a zero value field; size requires both trailing fields to be zero. A missing get contributes `INT64_MIN`, contains contributes 0 or 1, and size contributes the current size. Invalid traces return `-1`.

The result is signed FNV-1a 64-bit over all get/contains/size query values in operation order, then final map size and final `(key,value)` pairs in ascending key order, each encoded as eight little-endian bytes. Keys and values are bounded integers so the logical map operations have deterministic cross-language meaning.

The Java implementations share the same logical operations and separate-chaining collision strategy, but their hidden storage policies differ: the array version begins with 16 buckets and grows above load factor 0.75; the ArrayList version begins with 10 buckets and grows above 0.5. Neither exposes capacity or bucket iteration as a stable API, so this contract does not measure those private growth thresholds or `toString()` order. The existing `double_hash_hash_table` benchmark is a separate open-addressing algorithm with double hashing and tombstones, not an alias.

[`workload.json`](workload.json) includes collisions, updates, removals, absent queries, and enough inserts to cross both source growth thresholds. The runtime oracle is [`generic_hash_map_oracle.py`](../../generic_hash_map_oracle.py); the all-language verifier is [`verify_generic_hash_map.py`](../../verify_generic_hash_map.py).

Pinned sources: [Java array-backed buckets](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/hashmap/hashing/GenericHashMapUsingArray.java), [Java ArrayList-backed buckets](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/hashmap/hashing/GenericHashMapUsingArrayList.java).

## Implementations

| Language | Port |
|---|---|
| C | [`c/g/generic_hash_map.c`](../../../c/g/generic_hash_map.c) |
| C3 | [`c3/g/generic_hash_map.c3`](../../../c3/g/generic_hash_map.c3) |
| C++ | [`cpp/g/generic_hash_map.cpp`](../../../cpp/g/generic_hash_map.cpp) |
| Elisa | [`elisa/g/generic_hash_map.elisa`](../../../elisa/g/generic_hash_map.elisa) |
| Nim | [`nim/g/generic_hash_map.nim`](../../../nim/g/generic_hash_map.nim) |
| Odin | [`odin/g/generic_hash_map.odin`](../../../odin/g/generic_hash_map.odin) |
| Rust | [`rust/g/generic_hash_map.rs`](../../../rust/g/generic_hash_map.rs) |
| V | [`v/g/generic_hash_map.v`](../../../v/g/generic_hash_map.v) |
| Zig | [`zig/g/generic_hash_map.zig`](../../../zig/g/generic_hash_map.zig) |
