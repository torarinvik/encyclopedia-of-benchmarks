# Minimum Deletions to Make String Balanced

This benchmark implements the linear two-state dynamic program from the pinned C LeetCode 1653 candidate in TheAlgorithms/C. It returns the minimum deletions needed to leave every `a` before every `b`.

The packed input uses `0` for `a` and `1` for `b`, and accepts up to 256 symbols. Empty input returns 0; values outside 0..1 and longer inputs return -1. The recurrence tracks the best deletion count for a prefix assigned to either side of the `a* b*` boundary.

The verifier exhausts every binary sequence through length twelve, checks seeded inputs and malformed symbols, and tests maximum-length boundary patterns against an independent oracle that tries every split point. The pinned source is [TheAlgorithms/C LeetCode 1653](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1653.c). Run the verifier with the Elisa stage1 compiler path supplied.
