# Separate-chaining hash map

This package models the common logical operations of the pinned Java and TypeScript integer hash maps. It is a distinct benchmark from Python's open-addressing `hash_map` and from the existing `generic_hash_map` package.

## Contract

Input is a signed-i64 array `[operation_count, (opcode, key, value)*]` with at most 512 operations and 128 live mappings. Keys are non-null integers in `0..99,999`; values are non-null signed-i32 integers. The key bound keeps the pinned TypeScript implementation's decimal-string DJB2 hash nonnegative, so it always selects a valid bucket. The Java source uses `Integer` keys and values with 16 buckets; TypeScript begins with 16 buckets and may resize above load factor 0.75. Bucket sizing, growth, and chain iteration order are private details outside this logical-operation contract.

- Opcode 0 puts a key/value pair, updating the value when the key already exists.
- Opcode 1 gets a key. Its value field must be zero; an absent key returns no value.
- Opcode 2 deletes a key, with absent-key deletion as a no-op. Its value field must be zero.
- Opcode 3 checks whether a key exists. Its value field must be zero. Java's `search(key) != null` is equivalent on this non-null value domain, including when the mapped integer is zero.
- Opcode 4 clears the map; both trailing fields must be zero.

Each operation contributes an FNV-1a-64 record: opcode u8, result-code u8, and, only for a successful get, the returned signed-i32 value in little-endian order. Mutation operations and missing gets use result-code 0; successful gets use 1; `has` uses 0/1 for false/true. The final hash is masked to 63 bits and returned as a nonnegative i64, reserving `-1` for malformed input. The empty trace returns `5472609002491880229`. Out-of-range fields, malformed unused fields, unsupported opcodes, and insertion of a new key when 128 mappings are live return `-1`; updating an existing key at capacity is valid.

The pinned Java and TypeScript implementations both use separate chaining. The target ports use bounded integer keys with 16 modulo buckets and linked chains; key/value behavior is observable, while source-specific bucket growth and iteration order are not.

See [`workload.json`](workload.json), the [oracle](../../hash_map_separate_chaining_oracle.py), and the pinned [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/hashmap/hashing/HashMap.java) and [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/map/hash_map.ts) sources.

| Language | Port |
|---|---|
| C | [`c/h/hash_map_separate_chaining.c`](../../../c/h/hash_map_separate_chaining.c) |
| C3 | [`c3/h/hash_map_separate_chaining.c3`](../../../c3/h/hash_map_separate_chaining.c3) |
| C++ | [`cpp/h/hash_map_separate_chaining.cpp`](../../../cpp/h/hash_map_separate_chaining.cpp) |
| Elisa | [`elisa/h/hash_map_separate_chaining.elisa`](../../../elisa/h/hash_map_separate_chaining.elisa) |
| Nim | [`nim/h/hash_map_separate_chaining.nim`](../../../nim/h/hash_map_separate_chaining.nim) |
| Odin | [`odin/h/hash_map_separate_chaining.odin`](../../../odin/h/hash_map_separate_chaining.odin) |
| Rust | [`rust/h/hash_map_separate_chaining.rs`](../../../rust/h/hash_map_separate_chaining.rs) |
| V | [`v/h/hash_map_separate_chaining.v`](../../../v/h/hash_map_separate_chaining.v) |
| Zig | [`zig/h/hash_map_separate_chaining.zig`](../../../zig/h/hash_map_separate_chaining.zig) |
