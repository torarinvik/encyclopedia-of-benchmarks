# Linear Probing Hash Table

A bounded integer-key extraction of the two pinned C++ linear-probing table snapshots. It preserves the source’s zero empty sentinel, `-1` tombstone, duplicate insertion, linear probing, tombstone reuse, and growth at a post-insert load factor of at least one half.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[initial_capacity, operation_count, variable operation records...]`. Initial capacity is 2–16; there are 0–32 operations. Opcodes 0–3 consume a key and opcode 4 has no operand. The maximum valid and parseable input is 66 i64 words.
- Keys are positive signed i32 values in `1..2,147,483,520`. This excludes the source’s zero empty sentinel and `-1` tombstone, avoids negative signed remainder, and leaves room for `hash + probe_index` through table capacity 128.
- Opcodes are 0 add(key), 1 remove(key), 2 find(key), 3 hash(key), and 4 display(). Duplicate adds are permitted and occupy a separate probe slot. Remove requires a present key because the source’s absent-key path writes to the sentinel index and corrupts the table.
- The source grows the table by doubling when the post-insert load reaches one half. The maximum reachable table capacity under 32 operations is 128. Tombstones are skipped by lookup, reused by insertion, and dropped during rehash.
- Output records are little-endian signed i64 words: add `[0,1]`, remove `[1,1]`, find `[2,0|1]`, hash `[3,key]`, display `[4,capacity,slot0,...,slotN-1]`. Display encodes empty slots as `-2`, tombstones as `-1`, and stored keys as their positive values. Find reports the internal probing match for the requested key; it does not reproduce the CLI wrapper’s later sentinel-slot rendering check, which can misreport a miss when slot 0 contains another key.
- The hash behavior is source-equivalent only for the pinned target: C++17, Apple Clang 21.0.0, `arm64-apple-darwin27.0.0`, and Apple libc++. On this target, `std::hash<int>` is identity over the contracted key domain; cross-library/toolchain executions are outside this source-equivalence claim.
- Invalid input returns `-1` before output checks. Null input returns `-1`; null output or insufficient capacity returns `-2` without writes, including for a valid zero-output trace. Maximum output is 8,704 bytes.

## Workload

[workload.json](workload.json) covers collisions, growth, duplicate insertion, tombstone reuse, missing lookup, display encoding, invalid input, and exact/short maximum output. See the [oracle](../../linear_probing_hash_table_oracle.py).

## Pinned sources

- [TheAlgorithms/C-Plus-Plus `linear_probing_hash_table.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/hashing/linear_probing_hash_table.cpp) at `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`.
- [TheAlgorithms/C-Plus-Plus-1 `linear_probing_hash_table.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/hashing/linear_probing_hash_table.cpp) at `0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680`.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/l/linear_probing_hash_table.c](../../../c/l/linear_probing_hash_table.c) |
| C3 | [c3/l/linear_probing_hash_table.c3](../../../c3/l/linear_probing_hash_table.c3) |
| C++ | [cpp/l/linear_probing_hash_table.cpp](../../../cpp/l/linear_probing_hash_table.cpp) |
| Elisa | [elisa/l/linear_probing_hash_table.elisa](../../../elisa/l/linear_probing_hash_table.elisa) |
| Nim | [nim/l/linear_probing_hash_table.nim](../../../nim/l/linear_probing_hash_table.nim) |
| Odin | [odin/l/linear_probing_hash_table.odin](../../../odin/l/linear_probing_hash_table.odin) |
| Rust | [rust/l/linear_probing_hash_table.rs](../../../rust/l/linear_probing_hash_table.rs) |
| V | [v/l/linear_probing_hash_table.v](../../../v/l/linear_probing_hash_table.v) |
| Zig | [zig/l/linear_probing_hash_table.zig](../../../zig/l/linear_probing_hash_table.zig) |
