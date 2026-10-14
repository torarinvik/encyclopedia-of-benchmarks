# Binary search tree operation trace

The pinned inventory finds binary search tree implementations in 12 repositories. They cover ordered insertion, lookup, deletion, minimum/maximum queries, and several traversal orders. Duplicate-key policies differ: some sources ignore duplicates, others reject them or insert them to one side. This benchmark uses set semantics, so inserting an existing key is a successful no-op with result `0`. The tree is unbalanced, and deletion of a node with two children replaces it with its in-order predecessor.

## Contract

The `i64_array_scalar` function accepts zero to 1,024 signed 64-bit values encoded as `[opcode, payload]` pairs, for up to 512 operations. Keys range from -1,000,000 through 1,000,000. Opcodes are:

- `0`: insert a key; return `1` if newly inserted or `0` if it already exists
- `1`: delete a key; return `1` if found or `0` otherwise
- `2`: search for a key; return `1` if found or `0` otherwise
- `3`: return the minimum key, with payload zero
- `4`: return the maximum key, with payload zero
- `5`: return the tree size, with payload zero

Capacity is 256 distinct keys. Odd-length input, an unknown operation, an out-of-range key, a nonzero payload for operations 3–5, an insertion beyond capacity, an empty-tree minimum or maximum query, or input longer than 1,024 values returns `-1`. Empty input is valid. All implementations use an index-based node pool and a free list, avoiding architecture-specific instructions and dynamic allocation.

Every operation contributes `(operation_index + 1) * (observed_value + 1,000,000)` to the checksum. Remaining keys then contribute in ascending in-order traversal with one-based weights. Valid checksums are nonnegative and fit in signed 64-bit.

[`workload.json`](workload.json) contains 21 cases, including duplicate insertion, leaf/one-child/two-child/root deletion, missing keys, sorted insertion, node reuse, extrema, and capacity boundaries. The independent verifier checks 3,173 traces per implementation: all operation sequences through length three over representative operations, seeded randomized traces, malformed inputs, an over-limit input, and every workload case.

## Implementations

The nine portable implementations are in [`c/b/binary_search_tree.c`](../../../c/b/binary_search_tree.c), [`c3/b/binary_search_tree.c3`](../../../c3/b/binary_search_tree.c3), [`cpp/b/binary_search_tree.cpp`](../../../cpp/b/binary_search_tree.cpp), [`elisa/b/binary_search_tree.elisa`](../../../elisa/b/binary_search_tree.elisa), [`nim/b/binary_search_tree.nim`](../../../nim/b/binary_search_tree.nim), [`odin/b/binary_search_tree.odin`](../../../odin/b/binary_search_tree.odin), [`rust/b/binary_search_tree.rs`](../../../rust/b/binary_search_tree.rs), [`v/b/binary_search_tree.v`](../../../v/b/binary_search_tree.v), and [`zig/b/binary_search_tree.zig`](../../../zig/b/binary_search_tree.zig).

Run `python3 benchmarks/verify_binary_search_tree.py --elisa-compiler PATH/TO/elisac` to check all nine implementations against the independent ordered-set oracle and validate workload records.

## Upstream references

The pinned source APIs and duplicate-key behavior vary. These references document the reviewed sources:

- [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/binary_trees/binary_search_tree.c)
- [C-Plus-Plus](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/binary_search_tree.cpp)
- [C++ additional repository](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/binary_search_tree.cpp)
- [C-Sharp](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/BinarySearchTree/BinarySearchTree.cs)
- [Haskell](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/BinaryTree/BinarySearchTree.hs)
- [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Tree/BinarySearchTree.js)
- [Lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/sorted_set/binary_search_tree.lua)
- [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/binary_search_tree.py)
- [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/data_structures/binary_search_tree.r)
- [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/binary_search_tree.rs)
- [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/tree/binary_search_tree.ts)
- [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/search/binarySearchTree.zig)
