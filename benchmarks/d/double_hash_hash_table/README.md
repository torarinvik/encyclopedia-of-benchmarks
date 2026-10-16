# Double Hash Hash Table

This benchmark exercises open-addressed hashing with a key-dependent second probe step. It is distinct from linear and quadratic probing because each key follows its own arithmetic probe sequence.

## Contract

- Inputs use the signed 64-bit array ABI: `[prime_capacity, operation_count, operation_0, key_0, ...]`.
- Capacity is a prime from 3 through 101. There are at most 512 operations. Operation codes are `1` insert, `2` search, and `3` delete.
- The first bucket is `key mod capacity`; the step is `1 + key mod (capacity - 1)`. With prime capacity, every nonzero step visits every slot.
- Insert fails if the key is already present or the table is full. Search and delete fail for absent keys. Successful delete leaves a tombstone; insertion reuses a tombstone only after continuing far enough to rule out a duplicate.
- The result is the number of successful operations. Malformed layouts, nonprime/out-of-range capacities, and unknown operation codes return `-1`.

The pinned [C-Plus-Plus](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/hashing/double_hash_hash_table.cpp) and [C-Plus-Plus-1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/hashing/double_hash_hash_table.cpp) sources are interactive demonstrations, not portable callables. They use global mutable state, diagnostic I/O, an uninitialized empty-key sentinel, `std::hash`, and resizing. The shared contract isolates the double-hashing probe strategy with fixed deterministic integer hashes and explicit bounded semantics. The two repository copies express the same strategy and are not separate benchmark variants.

## Workload and verification

[`workload.json`](workload.json) includes colliding keys, negative keys, wraparound, tombstone reuse, a dense maximum-capacity table, and a small capacity. The independent oracle is [`benchmarks/double_hash_hash_table_oracle.py`](../../double_hash_hash_table_oracle.py), and [`benchmarks/verify_double_hash_hash_table.py`](../../verify_double_hash_hash_table.py) checks all nine language ports.

```sh
python3 benchmarks/verify_double_hash_hash_table.py
```
