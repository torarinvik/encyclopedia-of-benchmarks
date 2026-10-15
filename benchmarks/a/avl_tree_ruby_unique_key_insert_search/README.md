# AVL tree unique-key insertion and search (Ruby variant)

This package ports the pinned [TheAlgorithms/Ruby `avl_tree.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/binary_trees/avl_tree.rb). It preserves the source's unique-key insert, membership search, and in-order traversal behavior. The input contract omits deletion: the Ruby delete path can fail to rebalance and raises when deleting the final root leaf.

## Contract

Input is signed 64-bit slots `[operation_count, operation, key, ...]`. The operation count is 0 through 128; operation 0 inserts a key and operation 1 searches for a key. Keys are bounded integers in -1,000,000 through 1,000,000. Inserted keys must be unique, with at most 64 inserts. Search operations may query any key, including keys not yet inserted.

Output is `[inorder_count, sorted tree keys..., search_count, search_results...]`, encoded as little-endian signed 64-bit values. Search results are 1 for present and 0 for absent, in input order. The return value is the output byte length; malformed input returns `-1`, and insufficient or null output capacity returns `-2`. The result omits tree shape and height; the ports still perform AVL rotations during insertion.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/avl_tree_ruby_unique_key_insert_search.c`](../../../c/a/avl_tree_ruby_unique_key_insert_search.c) |
| C3 | [`c3/a/avl_tree_ruby_unique_key_insert_search.c3`](../../../c3/a/avl_tree_ruby_unique_key_insert_search.c3) |
| C++ | [`cpp/a/avl_tree_ruby_unique_key_insert_search.cpp`](../../../cpp/a/avl_tree_ruby_unique_key_insert_search.cpp) |
| Elisa | [`elisa/a/avl_tree_ruby_unique_key_insert_search.elisa`](../../../elisa/a/avl_tree_ruby_unique_key_insert_search.elisa) |
| Nim | [`nim/a/avl_tree_ruby_unique_key_insert_search.nim`](../../../nim/a/avl_tree_ruby_unique_key_insert_search.nim) |
| Odin | [`odin/a/avl_tree_ruby_unique_key_insert_search.odin`](../../../odin/a/avl_tree_ruby_unique_key_insert_search.odin) |
| Rust | [`rust/a/avl_tree_ruby_unique_key_insert_search.rs`](../../../rust/a/avl_tree_ruby_unique_key_insert_search.rs) |
| V | [`v/a/avl_tree_ruby_unique_key_insert_search.v`](../../../v/a/avl_tree_ruby_unique_key_insert_search.v) |
| Zig | [`zig/a/avl_tree_ruby_unique_key_insert_search.zig`](../../../zig/a/avl_tree_ruby_unique_key_insert_search.zig) |
