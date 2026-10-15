# Maximum Ice Cream Bars

This benchmark implements the greedy approach from the pinned C LeetCode 1833 candidate in TheAlgorithms/C: sort the costs in ascending order, then buy each next bar while the remaining budget can cover it.

The packed input starts with a budget in 0..1,000,000 and continues with 0 to 256 costs in 1..10,000. The output is the maximum affordable bar count. Invalid budgets, costs, or excess length return -1. Empty cost lists return 0. Each port copies costs into fixed local storage and uses the same portable insertion sort before the greedy purchase pass.

The verifier exhausts short cost sequences across several budgets, adds seeded inputs and maximum-length cases, and checks malformed inputs against a sorted-cost oracle. The pinned source is [TheAlgorithms/C LeetCode 1833](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1833.c). Run the verifier with the Elisa stage1 compiler path supplied.
