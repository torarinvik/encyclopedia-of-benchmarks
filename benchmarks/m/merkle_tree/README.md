# Merkle Tree

This package benchmarks the pinned [TheAlgorithms/Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/blockchain/merkle_tree.py). Each leaf is SHA-256 of its raw ASCII bytes. At each level, hash the ASCII concatenation of lowercase hexadecimal child digests; duplicate the final child when a level has an odd number of nodes. Return the final 64-byte lowercase hexadecimal root. The source’s directionless `verify_proof` is excluded.

The `i64_array_bytes_output` ABI uses the packed input layout `[leaf_count,(byte_length,ASCII bytes...)*]`. The workload records the exact input bounds, output encoding, invalid-input result `-1`, insufficient-capacity result `-2`, and bounded output workspace.

Time is O(total leaf bytes + total tree digest bytes); auxiliary space is O(number of tree nodes).

See [`workload.json`](workload.json) for boundary and invalid-input cases. The independent oracle is [`merkle_tree_oracle.py`](../../merkle_tree_oracle.py).

## Language ports

- C: [`c/m/merkle_tree.c`](../../../c/m/merkle_tree.c)
- C3: [`c3/m/merkle_tree.c3`](../../../c3/m/merkle_tree.c3)
- C++: [`cpp/m/merkle_tree.cpp`](../../../cpp/m/merkle_tree.cpp)
- Elisa: [`elisa/m/merkle_tree.elisa`](../../../elisa/m/merkle_tree.elisa)
- Nim: [`nim/m/merkle_tree.nim`](../../../nim/m/merkle_tree.nim)
- Odin: [`odin/m/merkle_tree.odin`](../../../odin/m/merkle_tree.odin)
- Rust: [`rust/m/merkle_tree.rs`](../../../rust/m/merkle_tree.rs)
- V: [`v/m/merkle_tree.v`](../../../v/m/merkle_tree.v)
- Zig: [`zig/m/merkle_tree.zig`](../../../zig/m/merkle_tree.zig)
