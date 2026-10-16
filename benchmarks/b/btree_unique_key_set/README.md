# B-tree unique-key set operations

This benchmark measures insertion, membership queries, deletion, and sorted traversal for a unique integer-key B-tree. It follows the common set behavior of the pinned C#, Go, Java, and Lua sources. Duplicate inserts and missing deletes are excluded because the source libraries handle those cases differently.

## Contract

Input is a signed 64-bit array:

```text
[insert_count, unique_insert_key..., query_count, query_key..., delete_count, present_delete_key...]
```

Keys are signed 32-bit integers. Queries run after all inserts and before any deletes. Every delete key must have been inserted and must not have been deleted earlier in the same input. The portable contract uses B-tree minimum degree 255 (509 keys maximum per node), matching Lua's default order 255; the C# and Java ports set degree 255, and the Go port uses a 509-key maximum node size. Inputs allow up to 2,048 inserts and 1,024 queries or deletes, within the 4,096-i64 ABI limit. The 600-key workload crosses Lua's 509-key root capacity and exercises a root split.

Output is a little-endian signed 64-bit vector:

```text
[query_count, (query_present_as_0_or_1)..., remaining_key_count, sorted_remaining_key...]
```

Success returns the output byte length. Invalid input returns `-1`; insufficient output capacity returns `-2`. The maximum output size is 24,592 bytes.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm btree_unique_key_set --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/btree_unique_key_set/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/btree_unique_key_set.c`](../../../c/b/btree_unique_key_set.c) |
| C3 | [`c3/b/btree_unique_key_set.c3`](../../../c3/b/btree_unique_key_set.c3) |
| C++ | [`cpp/b/btree_unique_key_set.cpp`](../../../cpp/b/btree_unique_key_set.cpp) |
| Elisa | [`elisa/b/btree_unique_key_set.elisa`](../../../elisa/b/btree_unique_key_set.elisa) |
| Nim | [`nim/b/btree_unique_key_set.nim`](../../../nim/b/btree_unique_key_set.nim) |
| Odin | [`odin/b/btree_unique_key_set.odin`](../../../odin/b/btree_unique_key_set.odin) |
| Rust | [`rust/b/btree_unique_key_set.rs`](../../../rust/b/btree_unique_key_set.rs) |
| V | [`v/b/btree_unique_key_set.v`](../../../v/b/btree_unique_key_set.v) |
| Zig | [`zig/b/btree_unique_key_set.zig`](../../../zig/b/btree_unique_key_set.zig) |

## Pinned sources

- [C# B-tree](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/BTree/BTree.cs)
- [Go B-tree](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/structure/tree/btree.go)
- [Java B-tree](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/BTree.java)
- [Lua sorted-set B-tree](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/sorted_set/btree.lua)
