# Intersection of Two Linked Lists

The pinned C LeetCode 160 source advances two list pointers together and switches each pointer to the other list’s head after it reaches the end. When the lists share a physical node, the pointers meet there; when they do not, both reach null together.

## Contract

- The packed input is `[first_length, second_length, first_node_ids..., second_node_ids...]`. Each list may contain 0–1,024 nodes.
- Node IDs range from 0 to `2^31 - 1`; the same ID in both lists denotes the same physical node. Each list is acyclic, and any shared IDs form an identical aligned suffix.
- Return the ID of the first shared node, or `-1` when the lists do not intersect. Return `-2` for malformed lengths or IDs.
- The ports preserve the two-pointer head-switching method and use O(m + n) time and O(1) auxiliary storage.

Run `python3 benchmarks/verify_intersection_of_two_linked_lists.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` from the repository root to check all nine ports against exhaustive shared-tail layouts, seeded cases, boundaries, malformed inputs, and the published workload.

## Inspected upstream source

- [C — LeetCode `160.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/160.c)
