# Minimum Steps to One

Compute the minimum number of operations needed to reach `n` from `1` using the pinned source's forward dynamic program.

## Contract

- The `scalar` ABI accepts one signed 64-bit integer `n`.
- Supported inputs are `1 <= n <= 10,000`. Other values return `-1`; the Python source raises `ValueError` for nonpositive inputs, which this ABI maps to the sentinel.
- Initialize every table entry to `n + 1`, set `table[1] = 0`, then scan `i=1..n-1`. In that order, relax `i+1`, `2*i` when in range, and `3*i` when in range, each with `table[i] + 1`. Return `table[n]`.
- The output is an exact integer count. The update order preserves the source implementation; all relaxations point to larger indices, so earlier table entries are final when scanned.

## Source semantics

The canonical pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/minimum_steps_to_one.py) uses tabulation from 1 upward. Its introductory examples describe the equivalent reverse operations: decrement by one, or divide by two or three when divisible. The source path was checked in the candidate inventory; no same-contract benchmark package was present.

## Workload

[`workload.json`](workload.json) includes the source examples, small boundaries, and the maximum supported input.
