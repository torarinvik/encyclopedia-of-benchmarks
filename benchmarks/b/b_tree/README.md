# B-tree multiset operation trace

This benchmark implements the pinned Rust B-tree's multi-key nodes, split-on-descent insertion, search, and in-order traversal. It is a distinct structure from [`binary_search_tree`](../binary_search_tree/README.md): the BST is an unbalanced set with deletion, while this B-tree maintains multiple ordered keys per node, rebalances by splitting full nodes, retains duplicate keys, and has no delete operation. It is also distinct from [`trie`](../../t/trie/README.md), which stores lowercase strings and prefix counts.

## Contract

- Input is `[branch_factor, operation_count, (opcode, payload) * operation_count]`.
- `branch_factor` is 2–8. It is the minimum degree: nodes hold at most `2 * branch_factor - 1` keys.
- At most 256 keys and 511 operations are accepted. Keys range from -1,000,000 through 1,000,000. The complete input is limited to 1,024 signed 64-bit values and must have exactly `2 + 2 * operation_count` values.
- Opcode `0` inserts a key. Every insertion returns `1`; duplicates are retained, matching the source's insert-before-equal behavior.
- Opcode `1` searches for a key and returns `1` if present or `0` otherwise.
- Opcode `2` traverses keys in ascending order and returns a fingerprint; its payload must be zero. The fingerprint folds each key as `hash = (hash * 257 + key + 1,000,001) mod 1,000,000,007`, starting at zero.
- The final scalar checksum weights every operation result and then every remaining key in ascending traversal order. Invalid input returns `-1`.

[`workload.json`](workload.json) covers empty state, duplicate keys, node splits at multiple levels, negative keys, larger branch factors, the key and operation limits, and malformed records. Runtime verification is pending.

## Upstream source

- [TheAlgorithms/Rust B-tree at the pinned revision](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/b_tree.rs)
