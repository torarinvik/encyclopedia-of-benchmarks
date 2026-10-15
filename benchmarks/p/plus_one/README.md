# Plus One

This benchmark implements the decimal carry algorithm from the pinned C LeetCode 66 candidate in TheAlgorithms/C. It increments the nonnegative integer represented by a sequence of decimal digits.

The input accepts 0 to 256 digits in 0..9; multi-digit inputs cannot have a leading zero. Empty input represents zero. The ABI returns the number of output digits and writes their ASCII decimal representation into the caller-provided buffer. Invalid digits or excess length return -1; insufficient output capacity returns -2.

The verifier exhausts canonical short digit sequences, adds seeded and maximum-length carry cases, and compares the decimal result with an independent arbitrary-precision integer oracle. It also checks invalid input and output-capacity failures. The pinned source is [TheAlgorithms/C LeetCode 66](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/66.c). Run the verifier with the Elisa stage1 compiler path supplied.
