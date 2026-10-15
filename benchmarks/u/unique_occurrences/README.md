# Unique Occurrences

This benchmark implements the C LeetCode 1207 algorithm from TheAlgorithms/C. It returns 1 when each distinct value appears a different number of times, and 0 when two values share a frequency.

The shared contract accepts 0 to 1,000 signed integers in -1,000..1,000. Empty input returns 1; invalid values or an overlength input return -1. Each port counts the bounded value range, then checks whether any positive frequency repeats.

The verifier checks every sequence through length eight over {-1, 0, 1}, deterministic random arrays, signed value boundaries, the maximum input length, malformed inputs, and the published workload against an independent Python frequency oracle. The pinned source is [TheAlgorithms/C LeetCode 1207](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1207.c). Run the verifier with the Elisa stage1 compiler path supplied.
