# Tree sort

Tree sort inserts each value into a binary search tree, then writes the values back in in-order traversal. The nine ports use an unbalanced tree, preserve duplicate values by inserting equal values into the right subtree, and sort signed 64-bit integers in place. The contract accepts up to 1024 values; average insertion time is `O(n log n)`, worst-case time is `O(n^2)`, and auxiliary storage is `O(n)`.

The pinned Rust, Python, and TypeScript sources retain duplicate values with different equal-value branch choices. The Java `TreeSort` delegates to `BSTRecursiveGeneric`, whose insertion ignores a value equal to an existing node, so it loses duplicates. The shared benchmark keeps duplicates and uses a consistent right-subtree rule. Its ports use iterative insertion and traversal, avoiding recursive call-stack growth on a degenerate tree while preserving the unbalanced BST algorithm.

Run `python3 benchmarks/verify_tree_sort.py` to check short-array ordering and duplicate patterns, signed boundaries, deterministic random arrays, and every published workload length in all nine languages.

## Upstream references

- [Java `TreeSort.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/TreeSort.java)
- [Python `tree_sort.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/tree_sort.py)
- [Rust `tree_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/tree_sort.rs)
- [TypeScript `tree_sort.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/sorts/tree_sort.ts)
- [lac-dcc/Benchmarks Stanford `Treesort.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Treesort/Treesort.c)
- [lac-dcc/Benchmarks Stanford `Treesort/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Treesort/info.sh)

The Stanford Treesort source inserts generated keys into a binary search tree and checks its ordering; it prints selected original keys instead of traversing the tree to emit a sorted sequence. Its duplicate-dropping insertion and fixed output profile are source-specific details of the same tree-sort structure, so the source is tracked here without a second package.
