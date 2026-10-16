# AVL tree unique-key operations

This package compares unique-key AVL insert, search, and delete operations. It normalizes the result to the sorted key set and search answers, so implementations are not compared by internal node layout or rotation choices. The source families represented here are Java, C#, JavaScript, PHP, C, Python, and Rust. PHP inserts use `value = key`, matching the integer-key map semantics. Every delete targets a key that is currently present.

## Contract

Input is a signed 64-bit vector `[operation_count, operation, key, ...]`. The count is 0 through 128. Operation 0 inserts a key that is not currently present, operation 1 searches for any key, and operation 2 deletes a key that is currently present. A deleted key may be inserted again later. Keys range from -1,000,000 through 1,000,000.

Output is `[inorder_count, sorted_keys..., search_count, search_results...]`, encoded as little-endian signed 64-bit values. Search results are 1 for present and 0 for absent, in input order. The return value is the output byte length; malformed traces return `-1`, and insufficient or null output capacity returns `-2` without writing output.

The workload covers all four insertion rotation shapes, leaf/one-child/two-child deletion, deletion of a root, reinsertion, searches before and after mutations, and invalid traces. It deliberately leaves the F# persistent tree and C++ insert-only tree under their own contracts. Ruby's insert/search behavior is also tracked separately because its delete path is not suitable for the shared delete workload.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm avltree_unique_key_ops --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/a/avltree_unique_key_ops/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/avltree_unique_key_ops.c`](../../../c/a/avltree_unique_key_ops.c) |
| C3 | [`c3/a/avltree_unique_key_ops.c3`](../../../c3/a/avltree_unique_key_ops.c3) |
| C++ | [`cpp/a/avltree_unique_key_ops.cpp`](../../../cpp/a/avltree_unique_key_ops.cpp) |
| Elisa | [`elisa/a/avltree_unique_key_ops.elisa`](../../../elisa/a/avltree_unique_key_ops.elisa) |
| Nim | [`nim/a/avltree_unique_key_ops.nim`](../../../nim/a/avltree_unique_key_ops.nim) |
| Odin | [`odin/a/avltree_unique_key_ops.odin`](../../../odin/a/avltree_unique_key_ops.odin) |
| Rust | [`rust/a/avltree_unique_key_ops.rs`](../../../rust/a/avltree_unique_key_ops.rs) |
| V | [`v/a/avltree_unique_key_ops.v`](../../../v/a/avltree_unique_key_ops.v) |
| Zig | [`zig/a/avltree_unique_key_ops.zig`](../../../zig/a/avltree_unique_key_ops.zig) |

## Pinned source references

- [Go `avl.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/structure/tree/avl.go) supplies unique-key insertion, lookup, traversal, and deletion.
- [Java `AVLSimple.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/AVLSimple.java) supplies the four AVL insertion rotations and maps on unique-insertion traces.
- C: [`avl_tree.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/binary_trees/avl_tree.c)
- C#: [`AVLTree.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/AVLTree/AVLTree.cs)
- Java: [`AVLTree.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/AVLTree.java)
- JavaScript: [`AVLTree.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Tree/AVLTree.js)
- PHP: [`AVLTree.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/AVLTree/AVLTree.php)
- Python: [`avl_tree.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/avl_tree.py)
- Rust: [`avl_tree.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/avl_tree.rs)
