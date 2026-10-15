# First Unique Character

Ports the frequency-table approach from [TheAlgorithms/C LeetCode 387](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/387.c): count each character, then return the first position whose character occurs once.

The shared ABI represents a string as lowercase ASCII values in an i64 array, with a maximum length of 1,024. It returns the zero-based first unique-character index, or -1 if every character repeats or the input is empty. Values outside a-z and overlong inputs return -2. The input is not modified. Runtime is O(n) and the fixed frequency table uses O(1) extra space.

Run python3 benchmarks/verify_first_unique_character.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1 from the repository root to check all nine ports against exhaustive short strings, signed and malformed values, randomized inputs, and the published workload.
