# Smallest Divisor

This benchmark implements the C LeetCode 1283 search from TheAlgorithms/C. It finds the least positive divisor for which the sum of each positive input value rounded up after division is no greater than the threshold.

The packed input starts with the threshold followed by 1 to 256 values in 1..1,000,000. The threshold is in 1..1,000,000. Invalid inputs and thresholds below the number of values return -1.

The verifier exhausts short arrays over values 1 through 5 and small thresholds, adds deterministic random inputs and value/length boundaries, and compares results to a direct scan of every divisor. The pinned source is [TheAlgorithms/C LeetCode 1283](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1283.c). Run the verifier with the Elisa stage1 compiler path supplied.
