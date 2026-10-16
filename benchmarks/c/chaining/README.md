# Chaining

This benchmark extracts the membership behavior of the two pinned C++
`hash_chain` console demonstrations. Keys use `key % bucket_count` to select a
bucket, inserts append to that bucket's linked chain, and queries report
whether the exact key is present. Duplicate inserts are allowed.

## Contract

- Input is `[bucket_count, operation_count, (operation, key)*]`.
- `bucket_count` is from 1 through 127. `operation_count` is from 0 through
  128. Each key is a nonnegative signed 32-bit integer.
- Operation `0` inserts its key. Operation `1` queries its key. The input must
  contain exactly two values per operation and may contain at most 63 queries.
- The return value is a bit mask in query order: bit 0 records the first query,
  bit 1 the second, and so on. A set bit means the key was found in its bucket.
- Malformed inputs return `-1`. The 63-query bound keeps the result within the
  nonnegative signed 64-bit range.
- Insertions scan to the end of a bucket chain before appending, matching the
  source's O(chain length) insertion cost. Lookups also take O(chain length).

The source classes also print an interactive menu and status text. The
benchmark preserves their hash and membership behavior while omitting console
I/O. Because keys are nonnegative, the source's signed remainder and absolute
value handling during insertion reduce to the same bucket index as `key %
bucket_count`.

## Workload and oracle

[`workload.json`](workload.json) covers empty tables, collisions, repeated
inserts, interleaved queries, large keys, and the query-bit limit. The
independent oracle is [`chaining_oracle.py`](../../chaining_oracle.py).

## Pinned sources

- [TheAlgorithms/C-Plus-Plus `chaining.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/hashing/chaining.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `chaining.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/hashing/chaining.cpp)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/chaining.c`](../../../c/c/chaining.c) |
| C3 | [`c3/c/chaining.c3`](../../../c3/c/chaining.c3) |
| C++ | [`cpp/c/chaining.cpp`](../../../cpp/c/chaining.cpp) |
| Elisa | [`elisa/c/chaining.elisa`](../../../elisa/c/chaining.elisa) |
| Nim | [`nim/c/chaining.nim`](../../../nim/c/chaining.nim) |
| Odin | [`odin/c/chaining.odin`](../../../odin/c/chaining.odin) |
| Rust | [`rust/c/chaining.rs`](../../../rust/c/chaining.rs) |
| V | [`v/c/chaining.v`](../../../v/c/chaining.v) |
| Zig | [`zig/c/chaining.zig`](../../../zig/c/chaining.zig) |

## Build and verify

All nine ports passed 4,631 oracle arrays each and all 15 workload records. The
verifier combines exhaustive short traces, seeded longer traces, and the
published workload against an independent bucket-list oracle.

```sh
python3 benchmarks/verify_i64_array_scalar.py --algorithms chaining --jobs 3 --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm chaining --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/c/chaining/rust/build.json
```
