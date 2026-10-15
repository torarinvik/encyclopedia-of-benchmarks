# Longest Square Streak in an Array

This benchmark is based on C LeetCode candidate [2501](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2501.c). Its canonical benchmark name is `longest_square_streak`.

## Contract

The input is a signed 64-bit array `[count, numbers...]`. It must contain 2 through 100,000 values, each between 2 and 100,000. Invalid input returns `-1`. Duplicate values do not lengthen a streak because the sorted square chain contains distinct values.

The function returns the longest chain length of at least two where each next value is the square of the previous value, or `-1` when no such chain exists. It does not modify the input.

The caller supplies a 400,004-byte workspace. It is interpreted as 100,001 signed 32-bit little-endian states indexed by value: zero means absent, one means present but not memoized, and values above one encode a memoized chain length plus one. A smaller workspace returns `-2` before writes. The scalar result is returned directly; the workspace does not contain a serialized output result.

## Implementation

All nine ports use the same memoized square-chain recurrence and the caller-provided workspace, avoiding per-language allocation behavior and large stack arrays. The runtime is `O(n + maxValue)` and workspace use is fixed at `O(maxValue)`. The implementation uses portable scalar integer operations and generic target settings.

## Workload and verification

The workload includes both LeetCode examples, duplicate values, short square chains, near-limit values, invalid inputs, and 100,000 input values. The verifier compares against an independent set-based oracle, checks the full input bound and insufficient workspace capacity, and records the workload through the shared byte-output runner.
