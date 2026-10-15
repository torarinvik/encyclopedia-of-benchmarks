# Max Consecutive Answers

Ports the sliding-window approach from [TheAlgorithms/C LeetCode 2024](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2024.c). The algorithm checks each of the two possible answer values and finds the longest window containing at most k other values.

The shared ABI packs k first, followed by answer bits (0 for F, 1 for T). It accepts 0 to 1,024 answer bits and requires 0 ≤ k ≤ the number of bits. It returns the longest run achievable after changing at most k answers; invalid inputs return -1. An empty answer sequence with k=0 returns 0. This is a length-prefixed numeric contract, so the implementations do not depend on string encoding, NUL termination, or machine-specific instructions. Runtime is O(n) with O(1) extra space.

Run python3 benchmarks/verify_max_consecutive_answers.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1 from the repository root to check all nine ports against an exhaustive binary-sequence oracle, boundary and malformed cases, randomized inputs, and the published workload.
