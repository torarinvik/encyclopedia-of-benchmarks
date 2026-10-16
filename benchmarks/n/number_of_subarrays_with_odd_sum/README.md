# Number of Subarrays With Odd Sum

This benchmark implements the C LeetCode 1524 prefix-parity counter from TheAlgorithms/C. It counts contiguous subarrays with odd sums and returns the count modulo 1,000,000,007.

The contract accepts 0 to 100,000 signed 32-bit values. Empty input returns 0; invalid values and overlength inputs return -1. The benchmark computes prefix parity directly, so its result stays defined even when the mathematical sum exceeds signed 32-bit range. The pinned C source accumulates the prefix in `int`, whose signed overflow is undefined in portable C.

The reusable contract oracle is [`number_of_subarrays_with_odd_sum_oracle.py`](../../number_of_subarrays_with_odd_sum_oracle.py). It applies the same input bounds and counts opposite-parity prefix pairs modulo 1,000,000,007.

The verifier exhausts short arrays over mixed odd/even signed values, checks seeded random arrays and signed boundaries, and includes the maximum length against a direct interval oracle for short cases and a prefix-count oracle for the long boundary. The pinned source is [TheAlgorithms/C LeetCode 1524](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1524.c). Run the verifier with the Elisa stage1 compiler path supplied.
