# Maximum Consecutive Ones

Return the length of the longest contiguous run of ones in a binary array. A single scan counts each current run and remembers the greatest count.

## Contract

- Input is an array of signed 64-bit integers with length 0 through 4,096.
- Every value must be 0 or 1.
- Return the maximum number of consecutive ones. Empty and all-zero arrays return 0.
- Invalid values and oversized arrays return -1.

## Workload and verification

[`workload.json`](workload.json) covers empty, zero-only, one-only, alternating, separated, prefix, suffix, and maximum-length arrays. [`benchmarks/verify_max_consecutive_ones.py`](../../verify_max_consecutive_ones.py) checks the nine ports against a run-group oracle on exhaustive short arrays, invalid values, deterministic random inputs, and every workload case.

## Reviewed TheAlgorithms sources

The pinned C [LeetCode filename `14.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/14.c) exports `findMaxConsecutiveOnes` and counts contiguous nonzero runs. The JavaScript [`MaxConsecutiveOnes.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/Sliding-Window/MaxConsecutiveOnes.js) uses a sliding window. The C LeetCode [`485.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/485.c) counts the same contiguous runs. These sources agree on the shared binary input domain.

## Implementations

All nine portable implementations use the shared i64-array/scalar ABI.
