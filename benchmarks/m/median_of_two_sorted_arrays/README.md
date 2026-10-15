# Median of Two Sorted Arrays

The input contains two individually sorted arrays. The implementation merges them in ascending order, then reads the middle item or pair. This is the algorithm in the pinned C LeetCode 4 source and is distinct from [`median`](../median/README.md), which sorts one unsorted array.

## Contract

- Encode the input as `[first_length, second_length, first_values..., second_values...]`.
- Each array may be empty, but their combined length must be 1 through 1,024.
- Values are signed 32-bit integers, and each input array must be sorted in nondecreasing order.
- Inputs that violate the contract return `-1`.
- The input is read only. The result is twice the statistical median: twice the middle value for odd lengths, or the sum of the middle pair for even lengths. This preserves half-integer medians in the signed 64-bit scalar ABI.
- Implementations validate both arrays, merge into a bounded local buffer, and select the middle value. Time is O(m+n); auxiliary space is O(m+n).

## Workload and verification

[`workload.json`](workload.json) includes empty-side inputs, odd and even totals, duplicates, negative half-integer medians, signed 32-bit boundaries, and the maximum combined length. [`benchmarks/verify_median_of_two_sorted_arrays.py`](../../verify_median_of_two_sorted_arrays.py) compares all nine ports against an independent sorting oracle, exercises malformed inputs, and checks every published workload record.

## Upstream source

- [TheAlgorithms/C LeetCode 4](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/4.c)
