# Skip List Unique Key Set

This package ports the pinned skip-list map and set variants using unique integer keys.

## Contract

Input is a signed 64-bit array `[operation_count, (operation, key)...]`, with 0 to 128 operations. Operation 0 inserts an absent key, operation 1 queries whether a key is present, and operation 2 deletes a present key. Duplicate insertion and deletion of a missing key are invalid; a key may be inserted again after it has been deleted. Keys are signed 32-bit values excluding `INT_MIN` and `INT_MAX`, which are reserved by the C# implementation as sentinels.

Output contains the final keys in ascending order as little-endian signed i64 values, with no count prefix. The function returns the number of bytes written. Invalid input returns `-1`; a null or undersized output buffer returns `-2` without writing. Map implementations store the key as its own value. The C++ port uses one stable non-null marker value. Tower heights and node topology are internal details and are not part of the comparison result.

## Pinned sources

- C++ [`data_structures/skip_list.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/skip_list.cpp)
- C++ mirror [`data_structures/skip_list.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/skip_list.cpp)
- C# [`DataStructures/LinkedList/SkipList/SkipList.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/LinkedList/SkipList/SkipList.cs)
- Java [`src/main/java/com/thealgorithms/datastructures/lists/SkipList.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/SkipList.java)
- Python [`data_structures/linked_list/skip_list.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/skip_list.py)
- Rust [`src/data_structures/skip_list.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/skip_list.rs)
- Zig [`tiger_style/skip_list.zig`](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/tiger_style/skip_list.zig)

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm skip_list_unique_key_set --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/s/skip_list_unique_key_set/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/s/skip_list_unique_key_set.c`](../../../c/s/skip_list_unique_key_set.c) |
| C3 | [`c3/s/skip_list_unique_key_set.c3`](../../../c3/s/skip_list_unique_key_set.c3) |
| C++ | [`cpp/s/skip_list_unique_key_set.cpp`](../../../cpp/s/skip_list_unique_key_set.cpp) |
| Elisa | [`elisa/s/skip_list_unique_key_set.elisa`](../../../elisa/s/skip_list_unique_key_set.elisa) |
| Nim | [`nim/s/skip_list_unique_key_set.nim`](../../../nim/s/skip_list_unique_key_set.nim) |
| Odin | [`odin/s/skip_list_unique_key_set.odin`](../../../odin/s/skip_list_unique_key_set.odin) |
| Rust | [`rust/s/skip_list_unique_key_set.rs`](../../../rust/s/skip_list_unique_key_set.rs) |
| V | [`v/s/skip_list_unique_key_set.v`](../../../v/s/skip_list_unique_key_set.v) |
| Zig | [`zig/s/skip_list_unique_key_set.zig`](../../../zig/s/skip_list_unique_key_set.zig) |
