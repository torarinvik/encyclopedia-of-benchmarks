# Linear Probing Hash Map

A bounded integer-key/value extraction of the pinned Java LinearProbingHashMap. It preserves Java Integer hashing, wraparound linear probing, update behavior, resizing, cluster rehash after deletion, and sorted key enumeration.

## Contract

- ABI: i64_array_bytes_output.
- Input is [initial_capacity, op_count, operation records...], with initial capacity 4–16, at most 32 operations, and exact operation framing. Keys and values are non-null signed 32-bit integers.
- Opcodes are 0 put(key,value), 1 get(key), 2 delete(key), 3 contains(key), 4 size(), and 5 keys(). Put consumes three words, get/delete/contains consume two, and size/keys consume one.
- Put grows the table before checking for an existing key when size > capacity/2, and updates an existing value without changing size. Hash slots start at (key & 0x7fffffff) % capacity; collisions probe forward with wraparound.
- Delete removes the key, rehashes the following occupied probe cluster, and then shrinks when size > 0 and size <= capacity/8. Keys returns all present keys in ascending signed integer order.
- Every operation emits a record: put [0,1]; get [1,tag,value] where tag 0 means found and tag 1 means absent (absent value is 0); delete [2,0|1]; contains [3,0|1]; size [4,size]; keys [5,count,sorted keys...]. Records are little-endian signed 64-bit words. The result is bytes written.
- Invalid input returns -1 before output checks. Null input returns -1. Null output or insufficient capacity returns -2 without writes. The maximum output is 2,560 bytes.

## Workload

[workload.json](workload.json) covers collision and wraparound, update-triggered growth, deletion-cluster rehash, shrinking, signed integer hashes, sorted keys, invalid traces, and maximum output capacity. See the [oracle](../../linear_probing_hash_map_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/l/linear_probing_hash_map.c](../../../c/l/linear_probing_hash_map.c) |
| C3 | [c3/l/linear_probing_hash_map.c3](../../../c3/l/linear_probing_hash_map.c3) |
| C++ | [cpp/l/linear_probing_hash_map.cpp](../../../cpp/l/linear_probing_hash_map.cpp) |
| Elisa | [elisa/l/linear_probing_hash_map.elisa](../../../elisa/l/linear_probing_hash_map.elisa) |
| Nim | [nim/l/linear_probing_hash_map.nim](../../../nim/l/linear_probing_hash_map.nim) |
| Odin | [odin/l/linear_probing_hash_map.odin](../../../odin/l/linear_probing_hash_map.odin) |
| Rust | [rust/l/linear_probing_hash_map.rs](../../../rust/l/linear_probing_hash_map.rs) |
| V | [v/l/linear_probing_hash_map.v](../../../v/l/linear_probing_hash_map.v) |
| Zig | [zig/l/linear_probing_hash_map.zig](../../../zig/l/linear_probing_hash_map.zig) |

## Pinned sources

- [TheAlgorithms/Java LinearProbingHashMap](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/hashmap/hashing/LinearProbingHashMap.java) at e43ec3897e48f23843972d02cd05a5bb1b6864a2.
- [TheAlgorithms/Java Map helper](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/hashmap/hashing/Map.java) at the same commit; it defines the masked hash index and contains behavior.

## Build and record

    python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm linear_probing_hash_map --language rust
    python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/l/linear_probing_hash_map/rust/build.json
    python3 benchmarks/verify_i64_array_bytes_output.py --algorithm linear_probing_hash_map
