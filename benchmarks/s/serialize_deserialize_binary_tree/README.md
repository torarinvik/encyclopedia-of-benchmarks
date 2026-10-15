# Serialize and deserialize a binary tree

This benchmark follows the pinned Python [`TreeNode.__repr__` and `deserialize`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/serialize_deserialize_binary_tree.py). The format is preorder: each node is `value,left,right`, and each missing child is the literal `null`. Deserialization builds the tree from that token stream; the benchmark then serializes the result with the source's canonical integer formatting.

## Contract

- Input is an array of ASCII byte values encoding a comma-separated preorder tree string. The string must encode exactly one complete tree and contain at most 127 non-null nodes. Input length is 1..2,200 bytes. `null` is valid as the root and round-trips to `null`.
- Node tokens are signed 32-bit decimal integers. For compatibility with Python `int`, this bounded domain allows an optional sign and ASCII whitespace around digits; leading zeroes and `+` signs are accepted and normalized in output. Integer underscores, Unicode bytes, and values outside signed 32-bit range are outside the benchmark domain.
- The output is the source-style canonical preorder serialization, returned as ASCII bytes. The function returns output length. Invalid input returns `-1`; insufficient output capacity returns `-2`.
- The source raises on empty input and malformed or incomplete trees. Its parser ignores extra comma-separated tokens after a complete tree; this benchmark requires the entire input to encode exactly one tree and maps other malformed inputs to `-1`.

This format is distinct from the indexed node-table serialization used by tree trimming and from traversal outputs. For a null root, this benchmark emits `null`; the pinned `repr(None)` would return Python's `None` because no node representation is invoked. The package also rejects trailing tokens after one complete tree, while the source parser ignores them.

| Language | Source |
| --- | --- |
| C | [`c/s/serialize_deserialize_binary_tree.c`](../../../c/s/serialize_deserialize_binary_tree/serialize_deserialize_binary_tree.c) |
| C3 | [`c3/s/serialize_deserialize_binary_tree.c3`](../../../c3/s/serialize_deserialize_binary_tree/serialize_deserialize_binary_tree.c3) |
| C++ | [`cpp/s/serialize_deserialize_binary_tree.cpp`](../../../cpp/s/serialize_deserialize_binary_tree/serialize_deserialize_binary_tree.cpp) |
| Elisa | [`elisa/s/serialize_deserialize_binary_tree.elisa`](../../../elisa/s/serialize_deserialize_binary_tree/serialize_deserialize_binary_tree.elisa) |
| Nim | [`nim/s/serialize_deserialize_binary_tree.nim`](../../../nim/s/serialize_deserialize_binary_tree/serialize_deserialize_binary_tree.nim) |
| Odin | [`odin/s/serialize_deserialize_binary_tree.odin`](../../../odin/s/serialize_deserialize_binary_tree/serialize_deserialize_binary_tree.odin) |
| Rust | [`rust/s/serialize_deserialize_binary_tree.rs`](../../../rust/s/serialize_deserialize_binary_tree/serialize_deserialize_binary_tree.rs) |
| V | [`v/s/serialize_deserialize_binary_tree.v`](../../../v/s/serialize_deserialize_binary_tree/serialize_deserialize_binary_tree.v) |
| Zig | [`zig/s/serialize_deserialize_binary_tree.zig`](../../../zig/s/serialize_deserialize_binary_tree/serialize_deserialize_binary_tree.zig) |
