# Check If Array Is Sorted and Rotated

This benchmark implements the C LeetCode 1752 check from TheAlgorithms/C. It determines whether an array is a rotation of a nondecreasing sequence.

The shared contract accepts 0 to 256 signed 32-bit integers. Empty input returns 1; values outside the signed 32-bit range and overlength inputs return -1.

The verifier exhausts arrays through length seven over {-1, 0, 1}, adds seeded random arrays and signed boundaries, and checks the workload against an independent oracle that sorts the input and tries every rotation. The pinned source is [TheAlgorithms/C LeetCode 1752](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1752.c). Run the verifier with the Elisa stage1 compiler path supplied.
