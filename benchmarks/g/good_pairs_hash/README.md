# Good pairs with a frequency map

Count index pairs `(i, j)` where `i < j` and the array values are equal. This
package preserves the pinned Ruby hash-table implementation's frequency-map
strategy, which is separate from the nested-loop `good_pairs` benchmark.

## Contract

- Input is a signed 64-bit integer array `[n, values...]`, with `n` from 0
  through 256 and exactly `n + 1` packed values. The `n` prefix is ABI metadata;
  ports validate and skip it, then apply the Ruby frequency-map algorithm to
  `values[1:]`. Each value is in `[-1,000,000, 1,000,000]`.
- Return the number of matching index pairs as a signed 64-bit integer.
  Empty and singleton arrays return zero; the maximum is `32,640`.
- Malformed input returns `-1`.
- Ports store each value's frequency in an open-addressed table, then sum
  `frequency * (frequency - 1) / 2`, matching the Ruby source's aggregation.
  The table has 512 slots for at most 256 distinct values.

## Source and workload

Pinned source: [TheAlgorithms/Ruby `good_pairs.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/hash_table/good_pairs.rb).
The separate nested-loop implementation in
[`data_structures/arrays/good_pairs.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/good_pairs.rb)
is covered by [`good_pairs`](../good_pairs/README.md).

[`workload.json`](workload.json) covers the Ruby examples, empty/singleton,
negative and boundary values, collisions, malformed packing, the header-equals-value
boundary, the maximum array size, and values outside the accepted domain.

## Running and verifying

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm good_pairs_hash --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/g/good_pairs_hash/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms good_pairs_hash --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/good_pairs_hash.c`](../../../c/g/good_pairs_hash.c) |
| C3 | [`c3/g/good_pairs_hash.c3`](../../../c3/g/good_pairs_hash.c3) |
| C++ | [`cpp/g/good_pairs_hash.cpp`](../../../cpp/g/good_pairs_hash.cpp) |
| Elisa | [`elisa/g/good_pairs_hash.elisa`](../../../elisa/g/good_pairs_hash.elisa) |
| Nim | [`nim/g/good_pairs_hash.nim`](../../../nim/g/good_pairs_hash.nim) |
| Odin | [`odin/g/good_pairs_hash.odin`](../../../odin/g/good_pairs_hash.odin) |
| Rust | [`rust/g/good_pairs_hash.rs`](../../../rust/g/good_pairs_hash.rs) |
| V | [`v/g/good_pairs_hash.v`](../../../v/g/good_pairs_hash.v) |
| Zig | [`zig/g/good_pairs_hash.zig`](../../../zig/g/good_pairs_hash.zig) |
