# Find All Duplicates in First-Seen Order

This benchmark ports the hash-table variant from Ruby's `find_all_duplicates_in_an_array.rb`. It counts each input value, then emits each value with count greater than one in the hash table's insertion order. Ruby preserves key insertion order, so results follow the first occurrence of each duplicated value, with each value emitted once even when it occurs more than twice.

## Contract

- Input is a read-only signed 64-bit integer array with length from 0 through 1,024.
- Return the number of distinct values that occur at least twice.
- Output stores those values in first-occurrence order as little-endian signed 64-bit integers. The input is unchanged.
- Empty input returns zero results. If the output buffer is too small, return `-2`; invalid input returns `-1`.
- The ports use a 2,048-slot open-addressing table and retain the insertion order of occupied slots.

The C ABI entry point is:

```c
int64_t find_all_duplicates_hash_order(const int64_t *input, size_t length,
                                       uint8_t *output, size_t capacity);
```

The sibling Ruby array implementation sorts and scans adjacent values, so it maps to the existing [`find_all_duplicates_in_array`](../../f/find_all_duplicates_in_array/README.md) benchmark on that contract's positive `1..n`, at-most-twice input domain. This package covers the distinct hash-table order behavior and unrestricted signed 64-bit values.

| Language | Source |
|---|---|
| C | [`c/f/find_all_duplicates_hash_order.c`](../../../c/f/find_all_duplicates_hash_order.c) |
| C3 | [`c3/f/find_all_duplicates_hash_order.c3`](../../../c3/f/find_all_duplicates_hash_order.c3) |
| C++ | [`cpp/f/find_all_duplicates_hash_order.cpp`](../../../cpp/f/find_all_duplicates_hash_order.cpp) |
| Elisa | [`elisa/f/find_all_duplicates_hash_order.elisa`](../../../elisa/f/find_all_duplicates_hash_order.elisa) |
| Nim | [`nim/f/find_all_duplicates_hash_order.nim`](../../../nim/f/find_all_duplicates_hash_order.nim) |
| Odin | [`odin/f/find_all_duplicates_hash_order.odin`](../../../odin/f/find_all_duplicates_hash_order.odin) |
| Rust | [`rust/f/find_all_duplicates_hash_order.rs`](../../../rust/f/find_all_duplicates_hash_order.rs) |
| V | [`v/f/find_all_duplicates_hash_order.v`](../../../v/f/find_all_duplicates_hash_order.v) |
| Zig | [`zig/f/find_all_duplicates_hash_order.zig`](../../../zig/f/find_all_duplicates_hash_order.zig) |

## Source

- [Ruby array `find_all_duplicates_in_an_array.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/find_all_duplicates_in_an_array.rb)
- [Ruby hash-table `find_all_duplicates_in_an_array.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/hash_table/find_all_duplicates_in_an_array.rb)
