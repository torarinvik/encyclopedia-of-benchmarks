# Threaded Binary Tree

This package follows the pinned Java [`ThreadedBinaryTree`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/ThreadedBinaryTree.java). It inserts the input keys into an insert-only threaded binary search tree, then emits the complete inorder traversal by following predecessor/successor threads. Equal keys go to the right subtree and remain present in the output.

## Contract

The `i64_array_bytes_output` input is `[n, key_0, ..., key_(n-1)]`, where `0 <= n <= 128`, the input length is exactly `1+n`, and every key is a signed 32-bit integer. Keys are inserted in their supplied order. A key strictly less than the current node goes left; an equal or greater key goes right.

The output is the inorder sequence encoded as consecutive little-endian signed i32 values, with no count prefix, separator, or NUL terminator. A successful call returns the number of output bytes (`4*n`), including `0` for an empty tree. Invalid counts, shapes, or keys return `-1` without writing output. An output buffer smaller than `4*n` bytes returns `-2` without writing output.

The bounded maximum supports 128 keys and 512 output bytes. The workload covers empty and singleton trees, increasing and decreasing insertion orders, mixed shapes, duplicates, signed i32 boundaries, invalid inputs, and insufficient capacity. The independent oracle is [`threaded_binary_tree_oracle.py`](../../threaded_binary_tree_oracle.py); the workload is [`workload.json`](workload.json).

## Implementations

| Language | Port |
|---|---|
| C | [`c/t/threaded_binary_tree.c`](../../../c/t/threaded_binary_tree.c) |
| C3 | [`c3/t/threaded_binary_tree.c3`](../../../c3/t/threaded_binary_tree.c3) |
| C++ | [`cpp/t/threaded_binary_tree.cpp`](../../../cpp/t/threaded_binary_tree.cpp) |
| Elisa | [`elisa/t/threaded_binary_tree.elisa`](../../../elisa/t/threaded_binary_tree.elisa) |
| Nim | [`nim/t/threaded_binary_tree.nim`](../../../nim/t/threaded_binary_tree.nim) |
| Odin | [`odin/t/threaded_binary_tree.odin`](../../../odin/t/threaded_binary_tree.odin) |
| Rust | [`rust/t/threaded_binary_tree.rs`](../../../rust/t/threaded_binary_tree.rs) |
| V | [`v/t/threaded_binary_tree.v`](../../../v/t/threaded_binary_tree.v) |
| Zig | [`zig/t/threaded_binary_tree.zig`](../../../zig/t/threaded_binary_tree.zig) |

Build and record with the `i64_array_bytes_output` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm threaded_binary_tree --language rust --with-checker
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/t/threaded_binary_tree/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm threaded_binary_tree --languages rust
```
