# Longest chunked palindrome decomposition

This benchmark implements the C LeetCode 1147 candidate from TheAlgorithms/C. It returns the largest number of nonempty consecutive chunks that concatenate to the input and form equal mirrored pairs, with a single center chunk when needed.

Inputs are sequences of 0 to 128 ASCII byte values from 1 through 127. The empty sequence returns 0. Invalid byte values and inputs longer than 128 return -1.

The ports repeatedly choose the shortest matching prefix and suffix, count two chunks, and peel them from the remaining sequence. If no matching pair remains, the middle is one chunk. The verifier uses a memoized exhaustive search over every matching boundary on short strings, plus boundary cases and deterministic random inputs, so its oracle does not rely on that greedy choice.

The C source is at [TheAlgorithms/C LeetCode 1147](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1147.c). Run the verifier with the Elisa stage1 compiler path supplied.
