# Bloom filter

Replay insert and membership-query operations against a fresh Bloom filter. Each query emits one byte: `1` when both of its bit positions are set and `0` otherwise. The filter never reports a false negative for inserted keys; a non-inserted key can be a false positive. Repeated insertion is idempotent. The operation set intentionally has no deletion.

## Contract

- The signed 64-bit input is a sequence of `(operation, key)` pairs: operation `1` inserts and operation `2` queries.
- A call starts with an empty 64-bit bit set. Keys are integers from `0` through `1,000,000,000`; at most 128 operations are accepted. An empty trace is valid.
- Both bit positions are derived deterministically: `h1 = (17 * key + 3) mod 64` and `h2 = (31 * key + 7) mod 64`. Insert sets both positions; query emits `1` only when both are already set. Hash collisions, including `h1 == h2` for some keys, are allowed.
- An odd-length trace, unknown operation, or out-of-range key returns `-1` without output. Insufficient output capacity returns `-2`. Otherwise return the number of query bytes written. Each output byte is exactly `0` or `1`.
- The routine takes `O(n)` time in the number of operations and `O(1)` auxiliary space.

## Relationship to source candidates

The source implementations all provide insert/add and membership checks, but choose incompatible filter sizes and hash derivations. C++ accepts caller-supplied hash functions; Rust includes one-hash and fixed-size variants as well as a dimensioned multi-hash filter; C# uses `GetHashCode`; Java derives positions from string hashes; Python combines SHA-256 and MD5. This benchmark fixes the bit count, number of positions, and hash derivation so results are deterministic and comparable across languages. It preserves the Bloom filter operation semantics, while excluding source-specific constructors and random seeds.

- [C++ `bloom_filter.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/bloom_filter.cpp)
- [Rust `bloom_filter.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/probabilistic/bloom_filter.rs)
- [C# `BloomFilter.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Probabilistic/BloomFilter.cs)
- [Java `BloomFilter.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/bloomfilter/BloomFilter.java)
- [Python `bloom_filter.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/hashing/bloom_filter.py)

## Workload and recording

Cases cover an empty filter, queries before and after insertion, duplicate insertion, an intentional false positive, mixed operations, the largest valid key, and invalid traces. The ports use the shared `i64_array_bytes_output` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm bloom_filter --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/bloom_filter/rust/build.json
```
