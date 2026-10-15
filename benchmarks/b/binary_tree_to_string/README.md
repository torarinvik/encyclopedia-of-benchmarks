# Binary tree to string

## Contract

This benchmark follows the pinned Java `BinaryTreeToString.tree2str` operation. It serializes one indexed binary tree to ASCII bytes with no trailing NUL. The packed input is `[node_count, root, (value, left, right)...]`; rows are in node-index order, and `-1` denotes a missing child. An empty tree uses `[0, -1]` and returns an empty string.

Node values are signed 32-bit integers and node count is 0 through 127. A nonempty tree must have a valid root index, child indices in `[-1, node_count)`, exactly one parent for each nonroot node, no parent for the root, and every node reachable from the root. Malformed packed input returns `-1`. If the output buffer cannot hold the full string, the function returns `-2` without writing output.

The source uses recursive preorder output. It appends each node's decimal value; an existing left subtree is written in parentheses, followed by an existing right subtree in parentheses. When a right child exists but the left child is absent, it writes `()` before the right subtree. It removes the outer parentheses around the root. For example, a root `1` with left child `2` and right child `3`, where `2` has right child `4`, becomes `1(2()(4))(3)`.

This format differs from [`serialize_deserialize_binary_tree`](../../s/serialize_deserialize_binary_tree/README.md), which uses comma-separated preorder values and explicit `null` tokens for both missing children. The empty tree differs too: `tree2str` returns the empty string.

## Workload and recording

[`workload.json`](workload.json) covers the empty tree, leaf, left-only and right-only children, the source example, negative values, and malformed tree layouts, and an insufficient-output-capacity call. It uses the `i64_array_bytes_output` ABI. The shared `run_i64_array_bytes_output.py` recorder computes the tree2str oracle and checks the published ASCII output.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm binary_tree_to_string --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/binary_tree_to_string/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binary_tree_to_string.c`](../../../c/b/binary_tree_to_string.c) |
| C3 | [`c3/b/binary_tree_to_string.c3`](../../../c3/b/binary_tree_to_string.c3) |
| C++ | [`cpp/b/binary_tree_to_string.cpp`](../../../cpp/b/binary_tree_to_string.cpp) |
| Elisa | [`elisa/b/binary_tree_to_string.elisa`](../../../elisa/b/binary_tree_to_string.elisa) |
| Nim | [`nim/b/binary_tree_to_string.nim`](../../../nim/b/binary_tree_to_string.nim) |
| Odin | [`odin/b/binary_tree_to_string.odin`](../../../odin/b/binary_tree_to_string.odin) |
| Rust | [`rust/b/binary_tree_to_string.rs`](../../../rust/b/binary_tree_to_string.rs) |
| V | [`v/b/binary_tree_to_string.v`](../../../v/b/binary_tree_to_string.v) |
| Zig | [`zig/b/binary_tree_to_string.zig`](../../../zig/b/binary_tree_to_string.zig) |

## Pinned source

- Java [`BinaryTreeToString.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/BinaryTreeToString.java)
