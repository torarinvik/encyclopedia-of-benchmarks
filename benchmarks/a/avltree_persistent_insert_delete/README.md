# Persistent AVL insert and delete

This benchmark ports the pinned F# AVL tree's immutable integer insert and delete operations. A node stores its key, height, and optional children. Empty trees have height `-1`, leaves have height `0`, and the balance factor is `right_height - left_height`. Insertions ignore duplicate keys; deletions of missing keys return an equivalent tree. Deleting a node with two children replaces it with the minimum key from the right subtree, then rebalances.

## Contract

Input is `[operation_count, (parent_version, operation, value)...]`. Version 0 is the empty tree. Each operation selects any already-created version, then appends a new version: operation 0 inserts the integer; operation 1 deletes it. Values are in `[-1000,1000]` and there are at most 32 operations. This permits branches from historical versions and exposes the source's persistent behavior: later operations cannot change earlier versions.

Output begins with the version count. Each version is represented as `[node_count, root_height, node_records...]`, where each record is `(value, height, left_local_id, right_local_id)` in breadth-first order. Child IDs are local to that version and missing children use `-1`. The return value is the byte count; all integers are little-endian signed i64. Invalid input returns `-1`; insufficient output capacity returns `-2` without writing.

The workload includes left-left and right-right rotations, left-right and right-left rotations, leaf and two-child deletion, and branches from earlier versions. It avoids duplicate inserts and missing deletes.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm avltree_persistent_insert_delete --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/a/avltree_persistent_insert_delete/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/avltree_persistent_insert_delete.c`](../../../c/a/avltree_persistent_insert_delete.c) |
| C3 | [`c3/a/avltree_persistent_insert_delete.c3`](../../../c3/a/avltree_persistent_insert_delete.c3) |
| C++ | [`cpp/a/avltree_persistent_insert_delete.cpp`](../../../cpp/a/avltree_persistent_insert_delete.cpp) |
| Elisa | [`elisa/a/avltree_persistent_insert_delete.elisa`](../../../elisa/a/avltree_persistent_insert_delete.elisa) |
| Nim | [`nim/a/avltree_persistent_insert_delete.nim`](../../../nim/a/avltree_persistent_insert_delete.nim) |
| Odin | [`odin/a/avltree_persistent_insert_delete.odin`](../../../odin/a/avltree_persistent_insert_delete.odin) |
| Rust | [`rust/a/avltree_persistent_insert_delete.rs`](../../../rust/a/avltree_persistent_insert_delete.rs) |
| V | [`v/a/avltree_persistent_insert_delete.v`](../../../v/a/avltree_persistent_insert_delete.v) |
| Zig | [`zig/a/avltree_persistent_insert_delete.zig`](../../../zig/a/avltree_persistent_insert_delete.zig) |

## Pinned source

- F# [`AVLTree.fs`](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/DataStructures/AVLTree.fs)
