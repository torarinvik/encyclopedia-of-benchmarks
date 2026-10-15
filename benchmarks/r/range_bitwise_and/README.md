# Range Bitwise AND

Compute the bitwise AND of every integer in an inclusive nonnegative range. The implementation preserves the reviewed source's method: repeatedly clear the least significant set bit of the upper endpoint until it equals the lower endpoint.

## Contract

- Inputs are unsigned 64-bit values, but valid range endpoints satisfy `0 <= left <= right <= 2^31 - 1`.
- Return the bitwise AND of all values from `left` through `right`, inclusive. Invalid bounds return `-1`.
- The loop changes only the upper endpoint and uses portable integer operations; it does not scan every integer in the range.

## Reviewed source

The pinned [C LeetCode 201 source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/201.c) applies `n &= n - 1` while `m < n`, then returns `n`. The benchmark uses the descriptive name `range_bitwise_and` for its implementation and exported function. Elisa identifiers used in declarations, including explicit module names, must begin with a letter, `_`, or `$`; the upstream candidate ID `201` remains catalog metadata, separate from source filenames and identifiers.

## Workload and verification

[`workload.json`](workload.json) covers empty-bit results, singleton ranges, power-of-two boundaries, the maximum endpoint, and invalid bounds. [`benchmarks/verify_binary_scalar.py`](../../verify_binary_scalar.py) checks the ports against a separate common-prefix oracle, exhaustive small ranges, bit-boundary pairs, and deterministic random ranges.

Build with the shared `binary_scalar` ABI and record with `benchmarks/run_binary_scalar.py`.
