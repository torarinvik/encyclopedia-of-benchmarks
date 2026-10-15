# Longest Palindromic Substring

This benchmark finds the longest contiguous palindrome in an ASCII alphanumeric string. It is cataloged under the algorithm name in the l directory. The pinned TheAlgorithms C reference describes expanding around odd and even centers; this implementation follows that portable O(n²) method and uses the caller's output buffer.

## Contract

- Input is a nonempty array of ASCII code points for digits or English letters, with a maximum length of 1,000.
- The result is the substring with the greatest length. If several have the same length, the leftmost is returned.
- The function returns the substring's byte length and writes exactly those bytes, without a NUL terminator or other mutation.
- Invalid input returns -1. Insufficient output capacity returns -2 without writing.
- The algorithm uses O(1) auxiliary space and no architecture-specific operations.

## Source and verification

The catalog candidate is TheAlgorithms/C leetcode/src/5.c, pinned at commit e5dad3fa8def3726ec850ca66a7f51521f8ad393. Its center-expansion approach is preserved, with safe caller-provided output storage. The original C source allocates sizeof(s) bytes for the result, which is only the pointer size and is insufficient for general inputs.

workload.json defines boundary, tie, invalid, and maximum-length cases. The verifier uses an independent dynamic-programming oracle and checks all nine language ports.
