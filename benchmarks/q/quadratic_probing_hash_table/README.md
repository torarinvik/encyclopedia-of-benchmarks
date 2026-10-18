# Quadratic probing hash table

This benchmark measures bounded insertion, lookup, deletion, tombstone reuse,
and rehash behavior from the pinned C++ `quadratic_probing` table. The console
menu and diagnostic printing are excluded; every call starts with fresh global
state.

## Contract

The signed-i64 input is
`[initial_capacity, operation_count, operation_0, key_0, ...]`. The initial
capacity is 1–8 and the operation count is 0–24. Operation selectors are `0`
insert, `1` remove, and `2` find. Keys are 1–64; 0 is the source's empty-slot
sentinel and -1 is its tombstone.

The source calls `std::hash<int>`. For reproducibility, this benchmark
normatively defines `hash(key) = key` for the bounded positive key domain. This
is a benchmark premise; it is not a C++ standard guarantee or a claim tied to a
pinned compiler/runtime. Probing visits
`(hash(key) + i²) % capacity`, beginning at `i = 0`. Insert uses the first
empty or tombstone slot. Find and remove continue past tombstones and stop at
an empty slot. An insert must reach an empty or tombstone slot before the
source's `100 * capacity` probe guard; scripts that exhaust this sequence are
invalid, so they cannot trigger the source's sentinel-0 fallback write.

Insertions must be unique among currently stored keys, and removals must name
a currently stored key. A key may be inserted again after it has been removed.
After every insertion, the source checks `size / capacity >= 0.5`; when true,
it doubles the capacity and reinserts active keys in old-slot order. Rehash
calls the same add path for each key, so an insertion during rehash can trigger
another doubling if it also reaches the 0.5 threshold. Tombstones are discarded
during rehash. The same probe-safety restriction applies to those reinsertions.

Find returns the key or 0. The source uses 0 both for “not present” and for a
probe result at slot 0; therefore a key stored at slot 0 is reported as 0 by
the `find` method. This observable sentinel behavior is retained.

The byte output is a sequence of little-endian signed 64-bit values:
`[final_capacity, active_size, find_count, find_results..., slot_0, ...]`.
Slots contain 0 when empty, -1 for a tombstone, or the stored key. The maximum
valid input length is 50 values and 51 values are parseable for a trailing-value
probe. With at most 24 operations, reaching capacity 64 takes 16 inserts and leaves
at most 8 finds, so the reachable maximum output is 600 bytes (3 header words,
8 result words, and 64 slot words).

Malformed framing, selectors, keys, duplicate live inserts, absent removals,
or an exhausted insertion probe return -1 before output checks. A null output
pointer or insufficient capacity returns -2 without writes. Output is never
partially written.

## Pinned source

- [TheAlgorithms/C-Plus-Plus `quadratic_probing_hash_table.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/hashing/quadratic_probing_hash_table.cpp), commit `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`.

## Workload and oracle

[`workload.json`](workload.json) covers an exactly sized output buffer, collision-driven
rehashing, tombstone reuse and lookup, maximum operation count, malformed
sequences, and output errors. The independent bounded state simulator is
[`benchmarks/quadratic_probing_hash_table_oracle.py`](../../quadratic_probing_hash_table_oracle.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/q/quadratic_probing_hash_table.c`](../../../c/q/quadratic_probing_hash_table.c) |
| C3 | [`c3/q/quadratic_probing_hash_table.c3`](../../../c3/q/quadratic_probing_hash_table.c3) |
| C++ | [`cpp/q/quadratic_probing_hash_table.cpp`](../../../cpp/q/quadratic_probing_hash_table.cpp) |
| Elisa | [`elisa/q/quadratic_probing_hash_table.elisa`](../../../elisa/q/quadratic_probing_hash_table.elisa) |
| Nim | [`nim/q/quadratic_probing_hash_table.nim`](../../../nim/q/quadratic_probing_hash_table.nim) |
| Odin | [`odin/q/quadratic_probing_hash_table.odin`](../../../odin/q/quadratic_probing_hash_table.odin) |
| Rust | [`rust/q/quadratic_probing_hash_table.rs`](../../../rust/q/quadratic_probing_hash_table.rs) |
| V | [`v/q/quadratic_probing_hash_table.v`](../../../v/q/quadratic_probing_hash_table.v) |
| Zig | [`zig/q/quadratic_probing_hash_table.zig`](../../../zig/q/quadratic_probing_hash_table.zig) |
