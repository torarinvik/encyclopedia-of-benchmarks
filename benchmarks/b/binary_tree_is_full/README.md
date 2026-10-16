# Binary Tree Is Full

Return whether every node in a binary tree has either zero children or two children. This package implements only the `is_full` operation from the broader Python/Dart basic binary-tree helpers; it does not include traversal, depth, or tree construction APIs.

## Contract

Input is a signed 64-bit array `[node_count, root, (left_child, right_child)*]`. Node indices are 0-based, `-1` denotes a missing child, and the input contains exactly one child pair per node. The bounded domain has 1 to 1,024 nodes. A valid input must describe one connected rooted tree: the root has no parent and every other node has exactly one parent.

The function returns 1 for a full tree, 0 for a valid tree that is not full, and -1 for malformed input. The Python and Dart sources agree for nonempty trees. Dart also returns true for a null root, but null trees are outside this package's nonempty indexed-tree contract.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm binary_tree_is_full --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/b/binary_tree_is_full/rust/build.json
```

## Verification

Run `python3 benchmarks/verify_binary_tree_is_full.py` to compare all nine implementations against generated valid and malformed trees, then record each published workload. If Elisa is not on `PATH`, pass `--elisa-compiler ../Elisa-compiler/bin/elisac-stage1`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binary_tree_is_full.c`](../../../c/b/binary_tree_is_full.c) |
| C3 | [`c3/b/binary_tree_is_full.c3`](../../../c3/b/binary_tree_is_full.c3) |
| C++ | [`cpp/b/binary_tree_is_full.cpp`](../../../cpp/b/binary_tree_is_full.cpp) |
| Elisa | [`elisa/b/binary_tree_is_full.elisa`](../../../elisa/b/binary_tree_is_full.elisa) |
| Nim | [`nim/b/binary_tree_is_full.nim`](../../../nim/b/binary_tree_is_full.nim) |
| Odin | [`odin/b/binary_tree_is_full.odin`](../../../odin/b/binary_tree_is_full.odin) |
| Rust | [`rust/b/binary_tree_is_full.rs`](../../../rust/b/binary_tree_is_full.rs) |
| V | [`v/b/binary_tree_is_full.v`](../../../v/b/binary_tree_is_full.v) |
| Zig | [`zig/b/binary_tree_is_full.zig`](../../../zig/b/binary_tree_is_full.zig) |

## Pinned sources

- Dart [`basic_binary_tree.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/data_structures/binary_tree/basic_binary_tree.dart)
- Python [`basic_binary_tree.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/basic_binary_tree.py)
