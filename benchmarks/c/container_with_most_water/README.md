# Container With Most Water

Given vertical lines whose heights are stored at consecutive positions, return the greatest area enclosed by two lines and the x-axis. The implementation starts with the outermost pair and moves the pointer at the shorter line inward. This takes linear time and constant extra space.

## Contract

- Input is an array of signed 64-bit integers with length 0 through 4,096.
- Every height must be between 0 and 2,147,483,647, matching the pinned C source's signed `int` values.
- Return the maximum of `(right index - left index) * min(left height, right height)` over all pairs with `left < right`.
- Arrays with fewer than two valid heights return 0. Oversized arrays and out-of-range heights return -1.
- The largest valid area fits in signed 64-bit arithmetic.

## Workload and verification

[`workload.json`](workload.json) covers empty and singleton arrays, the standard example, equal and monotone heights, zero-height lines, signed 32-bit height boundaries, and the maximum supported length. [`verify_container_with_most_water.py`](../../verify_container_with_most_water.py) checks all nine ports against a pair-enumeration oracle on exhaustive short arrays, boundaries, seeded random inputs, and every workload case.

## Reviewed TheAlgorithms source

The pinned C [LeetCode 11 implementation](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/11.c) uses this two-pointer strategy with signed `int` heights and area. The shared contract extends the result to signed 64-bit arithmetic so valid maximum areas cannot overflow.

## Implementations

All nine portable implementations use the shared i64-array/scalar ABI.
