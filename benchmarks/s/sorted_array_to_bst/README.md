# Sorted Array to BST

This benchmark builds a height-balanced binary search tree from a strictly increasing array of unique keys.

## Contract

- Input is a strictly increasing array of 0 to 64 signed 32-bit integers. Duplicate, descending, out-of-range, and overlong inputs return `-1`.
- The tree uses the lower middle element as each subtree root. Return the number of nodes.
- Output is preorder serialization: `00` marks a null child; `01` marks a node followed by its signed 32-bit key in little-endian byte order, then the left and right child serializations. An empty array serializes as `00` and returns 0.
- Insufficient output capacity returns `-2` without writing output.

The bounded input makes the full serialized tree fit in a small caller-owned buffer. Every target uses portable integer operations and the same deterministic midpoint rule.

## Inspected upstream source

The pinned [TheAlgorithms/C LeetCode file `108.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/108.c) recursively selects the midpoint and builds the left and right subtrees. The shared contract makes its sorted-input assumption explicit, supports the empty-array behavior in the source, validates strict ordering, and defines a portable serialized result.

## Workload and verification

[`workload.json`](workload.json) includes empty, singleton, even- and odd-length inputs, signed 32-bit boundaries, the maximum length, and invalid arrays. [`benchmarks/verify_sorted_array_to_bst.py`](../../verify_sorted_array_to_bst.py) compares the nine ports against a recursive serializer on every subset of a small ordered key set, deterministic random arrays, invalid cases, and an insufficient-output-capacity case.

```sh
python3 benchmarks/verify_sorted_array_to_bst.py --elisa-compiler /absolute/path/to/elisac
```

Build and record with the `i64_array_bytes_output` ABI family. Source ports are in `s/` in all nine language directories.
