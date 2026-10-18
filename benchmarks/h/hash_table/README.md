# Hash table: collision-free integer membership

This package defines the narrow behavior shared by the pinned C#, Python, and
Rust `HashTable` sources: insert distinct positive integers and query whether
integers are present. It does not model arbitrary key/value maps.

## Contract

- Input is a signed-i64 array laid out as
  `[insert_count, insert_keys..., query_count, query_keys...]`.
- Insert 0 through 8 distinct keys, then query 1 through 8 distinct keys.
  Each key is in `1..=1,000`; values are stored as the key itself.
- Every pair of distinct keys appearing in the trace must have different
  bucket indices modulo both 17 and 3,000. This removes collisions from all
  three source implementations. A query may repeat an inserted key to report
  membership.
- The traces stay below each source's resize threshold. C# uses its default
  capacity 16, which rounds up to 17; Python uses size 17 and its default
  charge settings; Rust uses its fixed initial capacity 3,000.
- Return one signed-i64 membership value per query (`1` if inserted, otherwise
  `0`), encoded as little-endian signed-i64 bytes in query order. The return
  value is the byte count.
- Invalid framing, duplicate insertions or queries, zero/out-of-range keys, or
  colliding distinct keys return `-1`. Input validation precedes output checks.
  A null output pointer or insufficient capacity returns `-2` without writing.

The source operations are adapted as follows: C# inserts `(key, key)` and uses
`ContainsKey`; Python calls `insert_data(key)` and reads membership from the
values returned by its `keys()` mapping; Rust inserts `(key, key)` and uses
`search`. The contract preserves only their shared unique-key membership
behavior. C# overwrites on collisions, Python probes, and Rust chains; those
different collision behaviors are outside this workload.

## Workload and oracle

[`workload.json`](workload.json) includes hits, misses, the C# bucket-zero
case, a maximum-size collision-free trace, duplicate/collision exclusions,
malformed framing, and output-capacity errors. The independent
[`hash_table_oracle.py`](../../hash_table_oracle.py) validates the trace
constraints and computes membership from a plain integer set.

The ABI family is `i64_array_bytes_output`; the function accepts an i64 array
and returns packed i64 membership values.

## Pinned sources

- [C# `HashTable.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Hashing/HashTable.cs)
- C# [`PrimeNumber.NextPrime`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Hashing/NumberTheory/PrimeNumber.cs), used to round the default capacity 16 to 17.
- [Python `hash_table.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/hashing/hash_table.py)
- [Rust `hash_table.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/hash_table.rs)
