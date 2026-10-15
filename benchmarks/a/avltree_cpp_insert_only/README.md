# C++ AVL Tree Insert Only

Insert a trace of unique integer keys into an AVL tree and return the keys in ascending order.

## Contract

- Input is a signed 64-bit array `[n, key_0, ..., key_(n-1)]`. The insertion count must be from 1 through 256, the array must contain exactly `n + 1` values, every key must fit a signed 32-bit integer, and keys must be unique. Invalid input returns -1.
- Output is the tree's keys in ascending order, encoded as little-endian signed 32-bit integers. The function returns the number of keys written. A null or undersized output buffer returns -2 without writing.
- The ports preserve the pinned C++ insertion behavior: compare keys, recurse into the selected child, compute subtree heights recursively, then apply the LL, LR, RR, or RL rotation when the balance factor exceeds one. The stored node height field in the source is not used by its height routine, so the ports also recompute heights recursively. The inorder traversal gives a canonical sorted-key result for every insertion order.
- The shared trace domain excludes duplicates and empty input. Deletion is excluded because the C++ demo's deletion routine does not rebalance the tree.

## Pinned sources

- [TheAlgorithms/C-Plus-Plus at fdcc29b](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/avltree.cpp)
- [TheAlgorithms/C-Plus-Plus-1 at 0f20cdcf](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/avltree.cpp)

## Implementations

Portable ports use `c/`, `c3/`, `cpp/`, `elisa/`, `nim/`, `odin/`, `rust/`, `v/`, and `zig/`, with the `i64_array_bytes_output` ABI family.
