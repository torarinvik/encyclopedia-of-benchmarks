# Sorted List to BST

This benchmark builds a height-balanced binary search tree from the values in a sorted singly linked list. The benchmark ABI supplies the linked-list sequence as an array so the same input can be passed to every language.

## Contract

- Input is a nondecreasing sequence of 0 to 64 signed 32-bit values. Descending, out-of-range, and overlong inputs return `-1`; duplicate values are allowed.
- For each recursive subtree, the midpoint follows the source's slow/fast pointer walk, selecting the upper middle node when the subtree length is even.
- Return the number of nodes. Output is preorder serialization: `00` marks a null child; `01` marks a node followed by its signed 32-bit key in little-endian byte order, then left and right children. An empty list serializes as `00` and returns 0.
- Insufficient output capacity returns `-2` without writing output.

The ports scan each input subrange to preserve the slow/fast midpoint-selection work, then serialize into caller-owned memory.

## Inspected upstream source

The pinned [TheAlgorithms/C LeetCode file `109.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/109.c) recursively uses slow and fast linked-list pointers to locate each subtree root, returning null for an empty list. The shared contract represents list values as a packed array and records the same upper-middle rule in its serialized result.

## Workload and verification

[`workload.json`](workload.json) covers empty, odd and even lengths, duplicates, signed 32-bit boundaries, maximum length, and invalid sequences. [`benchmarks/verify_sorted_list_to_bst.py`](../../verify_sorted_list_to_bst.py) compares the ports with an independent recursive serializer across exhaustive nondecreasing short sequences, deterministic arrays, malformed inputs, and insufficient capacity.

```sh
python3 benchmarks/verify_sorted_list_to_bst.py --elisa-compiler /absolute/path/to/elisac
```

Build and record with the `i64_array_bytes_output` ABI family. Source ports are in `s/` in all nine language directories.
