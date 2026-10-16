# Red-black tree unique-key operations

This package measures red-black tree insertion, membership search, and deletion while normalizing away the tree's shape. It follows the unique-key operation contract represented by the pinned C# and Python implementations.

Input is a signed 64-bit vector `[operation_count, (operation, key)...]`, with 0–128 operations. Keys must fit signed 32-bit integers. Operation `0` inserts a key that is currently absent, operation `1` searches for any key, and operation `2` deletes a key that is currently present. Duplicate active inserts and missing-key deletes are invalid; a deleted key may be inserted again. Malformed input returns `-1`.

Output is `[inorder_count, sorted_keys..., search_count, search_results...]`, encoded as little-endian signed 64-bit values. Search results are `1` for present and `0` for absent, in input order. The return value is the output byte length. A null output pointer or insufficient output capacity returns `-2` without writing output.

The nine ports maintain red-black trees with rotations and color fixups for both insertion and deletion. The pinned C# source rejects duplicate insertion and provides search, deletion, and in-order enumeration. The pinned Python source provides corresponding unique-key insertion, search, deletion, and ordered traversal behavior. The pinned C source is not treated as a verified matching implementation: its node allocator returns a pointer but does not return the allocated node, so its behavior cannot establish a reliable parity contract.

| Language | Port |
|---|---|
| C | [`c/r/red_black_tree_unique_key_ops.c`](../../../c/r/red_black_tree_unique_key_ops.c) |
| C3 | [`c3/r/red_black_tree_unique_key_ops.c3`](../../../c3/r/red_black_tree_unique_key_ops.c3) |
| C++ | [`cpp/r/red_black_tree_unique_key_ops.cpp`](../../../cpp/r/red_black_tree_unique_key_ops.cpp) |
| Elisa | [`elisa/r/red_black_tree_unique_key_ops.elisa`](../../../elisa/r/red_black_tree_unique_key_ops.elisa) |
| Nim | [`nim/r/red_black_tree_unique_key_ops.nim`](../../../nim/r/red_black_tree_unique_key_ops.nim) |
| Odin | [`odin/r/red_black_tree_unique_key_ops.odin`](../../../odin/r/red_black_tree_unique_key_ops.odin) |
| Rust | [`rust/r/red_black_tree_unique_key_ops.rs`](../../../rust/r/red_black_tree_unique_key_ops.rs) |
| V | [`v/r/red_black_tree_unique_key_ops.v`](../../../v/r/red_black_tree_unique_key_ops.v) |
| Zig | [`zig/r/red_black_tree_unique_key_ops.zig`](../../../zig/r/red_black_tree_unique_key_ops.zig) |

## Pinned source material

- C: [`red_black_tree.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/binary_trees/red_black_tree.c) (reviewed; allocator defect noted above).
- C#: [`RedBlackTree.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/RedBlackTree/RedBlackTree.cs).
- Python: [`red_black_tree.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/red_black_tree.py).

The workload is described in [`workload.json`](workload.json).
