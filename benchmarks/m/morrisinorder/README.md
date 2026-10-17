# Morris inorder traversal

This benchmark follows the pinned C++ implementation's Morris inorder traversal. Each call builds the complete binary tree that the source's sequential breadth-first `insert` calls create, then traverses it without a traversal stack. Temporary predecessor threads are removed before the traversal advances.

## Contract

- The packed `i64_array_bytes_output` input is `[n, node_0, ..., node_(n-1)]`. The node values are inserted in order; this produces the complete level-order tree.
- `n` is in `[0, 63]`, and every node value is a signed 32-bit integer. The frame length must be exactly `n + 1`.
- The output contains the inorder node values, each encoded as a signed 32-bit little-endian integer. Duplicate values are retained. A valid call returns `4 * n` bytes; the empty tree returns zero bytes.
- A null input, malformed frame, out-of-range node count, or out-of-range node value returns `-1`. A null output pointer or capacity below `4 * n` returns `-2` without writing. For an empty tree, the output pointer must still be nonnull; its capacity may be zero.
- The benchmarked call includes constructing the bounded complete-tree representation from the packed node values and performing the Morris traversal.

Sources: [C++ `morrisinorder.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/morrisinorder.cpp) and its equivalent [C-Plus-Plus-1 copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/morrisinorder.cpp).

Build and record with the `i64_array_bytes_output` ABI family and `benchmarks/run_i64_array_bytes_output.py`.
