# String to Integer

This benchmark ports the ASCII parsing behavior of LeetCode 8 (`atoi`) to a length-prefixed byte array and clamps results to signed 32-bit bounds.

## Contract

- Input contains 0 through 4,096 ASCII byte values in the range 1..127. Invalid lengths or bytes return `-2`.
- Skip leading ASCII spaces (`0x20`), consume one optional `+` or `-`, then parse the longest initial run of decimal digits. Other bytes stop parsing; if no digit is consumed, return `0`.
- Clamp overflow to `2,147,483,647` for positive values or `-2,147,483,648` for negative values.
- Runtime is O(n) and auxiliary space is O(1).

The workload covers signs, spaces, stopping characters, no-digit inputs, both overflow bounds, byte validation, and the maximum input length. All nine ports use the `i64_array_scalar` ABI family.

## Upstream reference

- [TheAlgorithms/C LeetCode 8 at the pinned catalog revision](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/8.c)
