# Parity outlier

Finds the sole value whose parity differs from all the other values in an integer array. The implementation follows the pinned JavaScript source's one-pass parity classification and count-based selection.

## Contract

- ABI: `i64_array_scalar`, packed input `[length, values...]`.
- The array length is odd and between 3 and 65. Each value is a nonnegative signed 32-bit integer, matching JavaScript's exact integer range.
- Valid arrays contain exactly one value of one parity and at least two values of the opposite parity. The result is that outlier value.
- Malformed arrays and arrays without exactly one parity outlier return `-1`. The source returns `null` for these cases; `-1` is the benchmark's invalid-result mapping and cannot be a valid result under the input bound.
- Implementations scan the values once, counting odd and even values while remembering the last seen value of each parity, as the source does. A parity with exactly one member has only one possible stored value.
- The minimum length excludes the source's two-element edge case: with one odd and one even value, its final conditional selects the odd value even though neither parity is a majority.

## Source and related algorithms

This package follows [TheAlgorithms JavaScript `ParityOutlier.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/ParityOutlier.js). The source uses `Number.isInteger`, stores each encountered even and odd value, and returns the value from the parity class whose count is one when the other class has more than one member.

This differs from [`is_even`](../../i/is_even/README.md) and [`is_odd`](../../i/is_odd/README.md), which classify one integer, and from [`number_appearing_odd_times`](../../n/number_appearing_odd_times/README.md), which finds an odd-frequency value rather than a parity outlier.

## Workload

[`workload.json`](workload.json) covers both outlier parities, zero, boundary values, arrays without one unique parity outlier, and malformed packed inputs.
