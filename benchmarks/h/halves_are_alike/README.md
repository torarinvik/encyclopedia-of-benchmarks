# Halves Are Alike

This benchmark implements the C LeetCode 1704 vowel-counting algorithm from TheAlgorithms/C. It counts ASCII vowels in each half and reports whether the counts match.

The shared contract accepts an even sequence of 0 to 256 ASCII letters. Empty input returns 1; odd lengths, nonletters, and overlength inputs return -1.

The verifier exhausts even strings through length six over a mixed-case vowel/consonant alphabet, adds seeded random strings and input boundaries, and checks the published workload against a direct Python count. The pinned source is [TheAlgorithms/C LeetCode 1704](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1704.c). Run the verifier with the Elisa stage1 compiler path supplied.
