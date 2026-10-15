# To Lower Case

This benchmark maps uppercase ASCII letters to lowercase and copies all other ASCII values unchanged. It is based on [TheAlgorithms/C LeetCode 709](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/709.c). The upstream source calls the locale-sensitive C `tolower` function and modifies its string in place. These ports use an explicit ASCII mapping, write to a separate output buffer, and behave consistently across platforms.

## Contract

- Input is an array of non-NUL 7-bit ASCII values (1 through 127), up to 4,096 values.
- Each uppercase value `A` through `Z` maps to the corresponding lowercase value. Other accepted values are copied unchanged.
- The output length equals the input length. Invalid values or lengths return `-1`; insufficient output capacity returns `-2`.
- The input is not modified. The transform takes O(n) time and O(1) auxiliary space.

LeetCode source stem `709` is cataloged under the algorithm name `to_lower_case` for alphabetic language-folder naming.

Run `python3 benchmarks/verify_to_lower_case.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` from the repository root to verify all nine ports against all one-byte ASCII inputs, exhaustive short sequences, seeded random inputs, invalid values, capacity failure, and the workload.

## Inspected upstream source

- [C — LeetCode `709.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/709.c)
