# Maximum Twin Sum of a Linked List

For an even-length list, the twins are the values at mirrored positions from the two ends. The pinned C LeetCode 2130 source copies the node values into an array and scans the first half against the mirrored second half. The ports keep that copy-and-scan algorithm with a bounded local array.

## Contract

- Input is a read-only array representing the linked-list values in list order.
- Length must be even and from 2 through 1,024.
- Values must be positive signed 32-bit integers from 1 through 100,000.
- Invalid inputs return `-1`.
- The result is the largest sum of a mirrored twin pair. The implementation uses O(n) time and O(n) auxiliary space.

## Workload and verification

[`workload.json`](workload.json) includes two-node and longer lists, equal values, a maximum away from the first pair, and the maximum allowed list length. [`benchmarks/verify_maximum_twin_sum_of_linked_list.py`](../../verify_maximum_twin_sum_of_linked_list.py) checks all nine ports against an independent mirrored-pair oracle, including exhaustive small lists, signed input errors, and maximum values.

## Upstream source

- [TheAlgorithms/C LeetCode 2130](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2130.c)
