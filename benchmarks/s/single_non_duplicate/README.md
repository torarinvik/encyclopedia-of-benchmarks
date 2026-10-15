# Single Non-Duplicate

Ports the O(log n) pair-alignment binary search from [TheAlgorithms/C LeetCode 540](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/540.c). In a sorted odd-length array, pairs align to even/odd indices before the unique value and odd/even indices after it. The search uses that parity change to halve the remaining interval on each step.

The shared ABI accepts a nonempty sorted array of at most 1,025 signed 32-bit values. Exactly one value occurs once; every other value occurs exactly twice. It returns the unique value. Empty, even-length, or over-capacity inputs return -2,147,483,649. Pair and sortedness requirements are input preconditions; the ports do not scan the array to validate them, preserving logarithmic search complexity. The input is not modified.

Run python3 benchmarks/verify_single_non_duplicate.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1 from the repository root to check exhaustive short pair layouts, deterministic random cases, signed boundaries, maximum length, and the workload.
