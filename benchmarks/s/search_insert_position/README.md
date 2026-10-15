# Search Insert Position

This benchmark implements the iterative binary-search version of the pinned C LeetCode 35 candidate from TheAlgorithms/C. It returns the zero-based index where a target is found or inserted into a sorted array.

The packed input starts with a signed 32-bit target, followed by 0 to 256 strictly increasing signed 32-bit values. Empty arrays return position 0. Out-of-range values, duplicate or unsorted array entries, and excess length return -1. The upstream file declares the same C function twice, once iteratively and once recursively; this benchmark follows the first, iterative binary-search definition.

The verifier exhausts small sorted arrays and target positions, checks seeded and signed-boundary inputs, and rejects malformed arrays against an independent linear insertion-position oracle. The pinned source is [TheAlgorithms/C LeetCode 35](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/35.c). Run the verifier with the Elisa stage1 compiler path supplied.
