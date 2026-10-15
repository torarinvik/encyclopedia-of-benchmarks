# Treap unique-key set

This benchmark ports the shared insert and erase behavior from the pinned C++, F#, Java, Lua, Python, and Rust treap implementations. Each operation keeps a binary-search tree ordered by key and restores the heap order by priority with rotations and subtree merges. The package uses a deterministic key-derived priority so every port has stable work while the contract compares only the final set, not the randomized topology.

## Contract

Input is a signed 64-bit array `[operation_count, (operation, key)...]`, with 0 to 128 operations. Operation `0` inserts a key and operation `1` deletes it. Keys are in `[-1,000,000, 1,000,000]`. An insert must target a key that is currently absent, and a delete must target a key that is currently present. Reinsertion after deletion is allowed. The input must have exactly `1 + 2 * operation_count` values. Invalid input returns `-1`.

Output is the final set in ascending key order, encoded as little-endian signed 64-bit integers. The function returns the number of keys written. A null or undersized output buffer returns `-2` without writing. An empty final set has zero output bytes and returns 0.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm treap_unique_key_set --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/t/treap_unique_key_set/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/treap_unique_key_set.c`](../../../c/t/treap_unique_key_set.c) |
| C3 | [`c3/t/treap_unique_key_set.c3`](../../../c3/t/treap_unique_key_set.c3) |
| C++ | [`cpp/t/treap_unique_key_set.cpp`](../../../cpp/t/treap_unique_key_set.cpp) |
| Elisa | [`elisa/t/treap_unique_key_set.elisa`](../../../elisa/t/treap_unique_key_set.elisa) |
| Nim | [`nim/t/treap_unique_key_set.nim`](../../../nim/t/treap_unique_key_set.nim) |
| Odin | [`odin/t/treap_unique_key_set.odin`](../../../odin/t/treap_unique_key_set.odin) |
| Rust | [`rust/t/treap_unique_key_set.rs`](../../../rust/t/treap_unique_key_set.rs) |
| V | [`v/t/treap_unique_key_set.v`](../../../v/t/treap_unique_key_set.v) |
| Zig | [`zig/t/treap_unique_key_set.zig`](../../../zig/t/treap_unique_key_set.zig) |

## Pinned sources

- C++ [`treap.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/treap.cpp)
- F# [`Treap.fs`](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/DataStructures/Treap.fs)
- Java [`Treap.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/Treap.java)
- Lua [`treap.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/sorted_set/treap.lua)
- Python [`treap.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/treap.py)
- Rust [`treap.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/treap.rs)
