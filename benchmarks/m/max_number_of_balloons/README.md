# Maximum Number of Balloons

This benchmark implements the C LeetCode 1189 counting algorithm from TheAlgorithms/C. It counts the available lowercase ASCII letters in the input and returns the minimum of the counts for b, a, l divided by two, o divided by two, and n.

The contract accepts 0 to 256 lowercase ASCII letters, encoded as integer values from 97 through 122. Empty input returns 0. Invalid bytes and longer inputs return -1.

The verifier exhausts all strings through length six over the five required letters, then checks deterministic boundary and random strings against an independent frequency-count oracle. The pinned source is [TheAlgorithms/C LeetCode 1189](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1189.c). Run the verifier with the Elisa stage1 compiler path supplied.
