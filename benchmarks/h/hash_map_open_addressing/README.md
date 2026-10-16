# Python open-addressing hash map

This benchmark ports TheAlgorithms/Python's `HashMap`: a mapping backed by a linearly probed bucket array, tombstones, and capacity growth and shrink. It is separate from `generic_hash_map`, which uses separate chaining, and from `double_hash_hash_table`, which uses a key-dependent second probe step.

## Contract

Input is a signed 64-bit array `[operation_count, (opcode, key, value)*]` with exactly `1 + 3 * operation_count` elements. There are at most 256 operations and at most 64 active distinct keys. Keys are in `0..1,000,000`; values are in `-1,000,000..1,000,000`.

Opcodes are `0` set/upsert, `1` get, `2` delete, `3` contains, and `4` size. Get, delete, and contains require a zero value field. Size requires both trailing fields to be zero. Get and delete require an existing key; `contains` may query either presence state. Malformed input, out-of-range data, an unknown opcode, a missing get/delete key, or more than 64 active keys returns `-1`.

The table starts with 8 buckets and capacity factor 0.75. Integer keys use their nonnegative integer value as the hash. Probing checks consecutive buckets with wraparound. Before every set, including an update, the table doubles when `size >= floor(capacity * 0.75)`. After a successful delete, the table halves when capacity is above 8 and `size < capacity * 0.75 / 2`. Resizing reinserts live entries in old bucket order and drops tombstones. A never-used bucket ends a lookup; a tombstone does not. A new key may reuse the first tombstone in its probe sequence.

The pinned Python source tests whether a stored item is falsy before comparing its key. Since its tombstone is falsy, setting a key that appears later in a probe sequence would create a duplicate. To keep the shared benchmark contract a unique-key map, such a trace is invalid: after any required growth, if an existing key is reached only after a tombstone, the operation returns `-1`. Updating a key reached before any tombstone remains valid. The workload covers tombstone reuse by a new key and lookup through tombstones.

Queries contribute `i * (answer + 1,000,001)` to the result, where `i` is the one-based query ordinal and `answer` is the get value, contains result (`0` or `1`), or current size. The final map contributes `j * (key_j + 1) * (value_j + 1,000,001)` for each pair in ascending key order, with `j` starting at 1. Add the final map size. The result remains within signed 64-bit range and cannot equal the invalid-input sentinel.

[`workload.json`](workload.json) covers collisions, tombstone traversal and reuse, growth, update-on-growth, shrinking to the initial capacity, invalid traces, and empty input. The independent oracle is [`hash_map_open_addressing_oracle.py`](../../hash_map_open_addressing_oracle.py); shared runner and verifier integration is handled separately.

Pinned source: [TheAlgorithms/Python `hash_map.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/hashing/hash_map.py).

## Implementations

| Language | Port |
|---|---|
| C | [`c/h/hash_map_open_addressing.c`](../../../c/h/hash_map_open_addressing.c) |
| C3 | [`c3/h/hash_map_open_addressing.c3`](../../../c3/h/hash_map_open_addressing.c3) |
| C++ | [`cpp/h/hash_map_open_addressing.cpp`](../../../cpp/h/hash_map_open_addressing.cpp) |
| Elisa | [`elisa/h/hash_map_open_addressing.elisa`](../../../elisa/h/hash_map_open_addressing.elisa) |
| Nim | [`nim/h/hash_map_open_addressing.nim`](../../../nim/h/hash_map_open_addressing.nim) |
| Odin | [`odin/h/hash_map_open_addressing.odin`](../../../odin/h/hash_map_open_addressing.odin) |
| Rust | [`rust/h/hash_map_open_addressing.rs`](../../../rust/h/hash_map_open_addressing.rs) |
| V | [`v/h/hash_map_open_addressing.v`](../../../v/h/hash_map_open_addressing.v) |
| Zig | [`zig/h/hash_map_open_addressing.zig`](../../../zig/h/hash_map_open_addressing.zig) |
