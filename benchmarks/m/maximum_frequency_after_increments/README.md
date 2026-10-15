# Maximum Frequency After Increments

This benchmark implements the sort-and-sliding-window algorithm from the pinned C LeetCode 1838 candidate in TheAlgorithms/C. It finds the largest group that can be made equal by incrementing values within a shared budget.

The packed input starts with a budget in 0..1,000,000, followed by 0 to 256 values in 1..10,000. The output is the maximum achievable frequency. Empty value lists return 0; invalid budgets, values, or excess length return -1. Each port sorts a local copy, then maintains the sum of a window whose values can all be raised to its largest value within budget.

The verifier exhausts short value arrays over several budgets, adds seeded and maximum-length arrays, and compares against an independent target-value/increment-cost oracle. The pinned source is [TheAlgorithms/C LeetCode 1838](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1838.c). Run the verifier with the Elisa stage1 compiler path supplied.
