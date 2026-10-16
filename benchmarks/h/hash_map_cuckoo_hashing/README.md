# Cuckoo hash map

This package benchmarks the pinned Java two-hash cuckoo table under two bounded insertion domains that preserve its resize and relocation behavior.

## Contract

The `i64_array_scalar` input is `[initial_capacity, key_count, key_0, ..., key_(key_count-1)]`, with exact length `key_count + 2`. Capacity is a power of two from 16 to 256. There are at most 128 unique signed 32-bit keys, excluding `INT_MIN` (the source's empty-slot sentinel). Valid inputs must satisfy either:

- **One relocation:** exactly two keys have the same first-hash bucket, and the first key's second-hash bucket differs from that shared bucket.
- **Distinct first buckets:** every key has a distinct first-hash bucket at the initial capacity.

The Java hashes use signed division/remainder with negative results corrected by adding the table size. The first hash is `key % capacity`; the second is `(key / capacity) % capacity`, where division truncates toward zero. The source grows the table when the load factor exceeds 0.7. Inputs outside the two safe classes, malformed records, duplicate keys, and `INT_MIN` return `-1`.

The output record is `[size, find_index(key_0), ..., find_index(key_n)]` in insertion order. Each record word is encoded as a signed 64-bit little-endian value and fed to wrapping FNV-1a-64; the result is masked to 63 bits. For an empty input set, the record is `[0]`.

The independent [oracle](../../hash_map_cuckoo_hashing_oracle.py) and [`workload.json`](workload.json) cover empty input, first-hash insertion, one relocation, load-factor growth, negative keys, and invalid domains.

Pinned source: [TheAlgorithms/Java `HashMapCuckooHashing.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/hashmap/hashing/HashMapCuckooHashing.java).

| Language | Port |
|---|---|
| C | [`c/h/hash_map_cuckoo_hashing.c`](../../../c/h/hash_map_cuckoo_hashing.c) |
| C3 | [`c3/h/hash_map_cuckoo_hashing.c3`](../../../c3/h/hash_map_cuckoo_hashing.c3) |
| C++ | [`cpp/h/hash_map_cuckoo_hashing.cpp`](../../../cpp/h/hash_map_cuckoo_hashing.cpp) |
| Elisa | [`elisa/h/hash_map_cuckoo_hashing.elisa`](../../../elisa/h/hash_map_cuckoo_hashing.elisa) |
| Nim | [`nim/h/hash_map_cuckoo_hashing.nim`](../../../nim/h/hash_map_cuckoo_hashing.nim) |
| Odin | [`odin/h/hash_map_cuckoo_hashing.odin`](../../../odin/h/hash_map_cuckoo_hashing.odin) |
| Rust | [`rust/h/hash_map_cuckoo_hashing.rs`](../../../rust/h/hash_map_cuckoo_hashing.rs) |
| V | [`v/h/hash_map_cuckoo_hashing.v`](../../../v/h/hash_map_cuckoo_hashing.v) |
| Zig | [`zig/h/hash_map_cuckoo_hashing.zig`](../../../zig/h/hash_map_cuckoo_hashing.zig) |
