# C++ LRU cache operations

This benchmark traces the pinned C++ `LRUCache<K, V>` API from
[`lru_cache2.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/lru_cache2.cpp).
The cache stores key/value pairs in a doubly linked list and maps keys to list
nodes. A successful `get` moves that node to the most-recently-used head; a
`put` inserts a new key at the head and evicts the least-recently-used tail
when the cache is full.

## Contract

The ABI is `i64_array_bytes_output`. Input is packed as
`[capacity, operation_count, (opcode, arg1, arg2)*]`. Capacity is 2–64 and
there are 0–256 operations. The input length must be exactly
`2 + 3 * operation_count`; 770 words is the maximum valid length, and 771 is
the maximum parseable length used to reject trailing input.

The safe common input domain uses signed-i32 keys and values, distinct keys
across all `put` operations, and `get` operations only for keys currently in
the cache. These restrictions avoid the pinned source's exception and update
paths while preserving its `put`, `get`, `size`, `capacity`, and `empty` API.
Capacity is bounded to a small positive value to keep traces and outputs
bounded.

Operation codes are:

| Code | Operation | Arguments |
|---:|---|---|
| 0 | `put(key, value)` | `arg1=key`, `arg2=value` |
| 1 | `get(key)` | `arg1=key`, `arg2=0` |
| 2 | `size()` | both arguments zero |
| 3 | `capacity()` | both arguments zero |
| 4 | `empty()` | both arguments zero |

Each operation emits one little-endian signed-i64 result. `put`, whose source
method returns `void`, emits `INT64_MIN`; `get` emits the cached i32 value;
`size` and `capacity` emit their integer results; `empty` emits 1 or 0. A valid
trace returns `8 * operation_count` bytes, up to 2,048. Invalid input returns
`-1` before output-buffer checks. A null output pointer returns `-2`, including
when the trace emits zero bytes. For an empty trace, a nonnull output pointer
with zero capacity succeeds and returns zero. For nonempty output, insufficient
capacity returns `-2`. Errors write nothing.

The independent reference implementation is
[`benchmarks/lru_cache2_oracle.py`](../../lru_cache2_oracle.py), and the
review workload is in [`workload.json`](workload.json).

## Reproduce

~~~sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm lru_cache2 --language cpp
python3 benchmarks/run_i64_array_bytes_output.py --algorithm lru_cache2
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm lru_cache2 --languages cpp
~~~

## Pinned source

The benchmark pins `others/lru_cache2.cpp` at C-Plus-Plus commit
`fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`, symbol
`others::Cache::LRUCache<int, int>`.

Ports will be listed here after the contract review.
