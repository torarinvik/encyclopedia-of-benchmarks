# HyperLogLog

Estimate the cardinality of a bounded set using the behavior of the pinned C# HyperLogLog implementation.

## Contract

- `i64_array_scalar` input is `[n, value_0, ..., value_(n-1)]`, with `n` from 1 through 1024 and exactly `n + 1` signed 64-bit words.
- Every value must be an integer from 1 through 65,535. Duplicates are allowed. Malformed or out-of-range input returns `-1`.
- For these positive values, `int.GetHashCode()` is the value itself and the source's binary-prefix register index is the full value. The rank is the position of the lowest set bit, counted from zero. Repeated values update one register and count once.
- Let `k` be the number of distinct values and `z` the sum of `2^-rank` over those touched registers. Return `ceil(0.673 * k * (k / z))`.

The estimate preserves the source's touched-register-only sum, alpha constant, and formula. It does not apply the textbook HyperLogLog corrections. The positive input bound avoids the source's zero and negative `Math.Log2` edge cases and keeps register indices in the source's 65,536-register table.

## Workload and verification

[`workload.json`](workload.json) covers repeated values, different register ranks, the highest register index, the maximum input count, and invalid bounds. [`hyper_log_log_oracle.py`](../../hyper_log_log_oracle.py) computes the registers and cardinality independently.

## Reviewed source

- [C# HyperLogLog.cs](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Probabilistic/HyperLogLog.cs)

The nine portable implementations use the shared i64-array scalar ABI and live in each language's `h` folder.
