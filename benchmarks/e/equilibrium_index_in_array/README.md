# Equilibrium index in an array

Return the first index where the sum of values to its left equals the sum of values to its right, following the pinned Python implementation.

## Contract

- The `i64_array_scalar` ABI receives `[n, values...]`: `n` is the number of values, followed by exactly `n` signed 32-bit integers.
- `n` is from 0 through 1,024. The result is the first matching zero-based index, or `-1` when no index matches. The current element is excluded from both side sums.
- The source first sums the array, then scans left to right, subtracting the current value from the remaining total before comparing it with the left sum. It returns immediately on the first match.
- Malformed packed input, lengths outside the bound, or values outside signed 32-bit range return `-2`. The sum magnitude is at most `1,024 * 2^31`, safely inside signed 64-bit range.

## Source and related names

This package follows [TheAlgorithms Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/equilibrium_index_in_array.py). The catalog's Dart `pivot_index` candidate implements the same first-index comparison, including empty input => `-1` and a singleton => `0`; it is treated as an alias of this package.

## Workload

[`workload.json`](workload.json) covers empty and singleton arrays, the pinned examples, negative and zero values, multiple matching positions, and malformed packed inputs. The runner uses `i64_array_scalar`.
