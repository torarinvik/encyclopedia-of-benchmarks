# Path Sum

This benchmark checks whether a binary tree contains a root-to-leaf path whose values add to a requested target. A leaf must end the matching path; matching a sum at an internal node is insufficient.

## Contract

- Input is `[target, node_count, value_0, left_0, right_0, ...]`. The root is node 0, and `-1` denotes a missing child.
- There are 0 to 63 nodes. Node values are signed 32-bit integers; the target is signed 64-bit. Every non-root node must be reachable exactly once from the root.
- Return `1` when a root-to-leaf path sums to the target, `0` when no path matches or the tree is empty, and `-1` for malformed tables or tree structure.
- Each port validates the indexed tree before recursively checking paths. With the node limit, every path sum fits signed 64-bit.

## Inspected upstream source

The pinned [TheAlgorithms/C LeetCode file `112.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/112.c) recursively subtracts each node value from the remaining target and accepts a match only at a leaf. The shared contract represents pointer-linked nodes by validated child indices and uses a wider target range.

## Workload and verification

[`workload.json`](workload.json) covers empty trees, single leaves, negative values, internal-node false positives, deep and wide trees, signed target boundaries, and malformed structures. [`benchmarks/verify_path_sum.py`](../../verify_path_sum.py) exhausts every binary-tree shape through four nodes over small value assignments and target values, adds deterministic trees up to 63 nodes, and checks malformed inputs in all nine languages.

```sh
python3 benchmarks/verify_path_sum.py --elisa-compiler /absolute/path/to/elisac
```

Build and record with the `i64_array_scalar` ABI family. Source ports are in `p/` in all nine language directories.
