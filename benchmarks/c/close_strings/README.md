# Close Strings

This benchmark implements the C LeetCode 1657 frequency check from TheAlgorithms/C. Two strings are close when they have the same character set and the same multiset of character frequencies.

The packed input contains both string lengths followed by their lowercase ASCII bytes. Each string may contain 0 to 256 letters. Malformed lengths or bytes return -1; unequal valid lengths return 0.

The verifier compares every pair of strings up to length four over a three-letter alphabet, seeded longer pairs, maximum-length strings, malformed packed layouts, and the workload against an independent Python Counter oracle. The pinned source is [TheAlgorithms/C LeetCode 1657](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1657.c). Run the verifier with the Elisa stage1 compiler path supplied.
