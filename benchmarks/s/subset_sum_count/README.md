# Subset Sum Count

Count the indexed subsets whose values add to a requested target. Duplicate values at different positions count as different choices. The empty subset is included when the target is zero.

## Contract

- The input is `[target, item0, ...]`; an input containing only the target is valid.
- There may be at most 24 items. Each item and the target must be in `[-6144, 6144]`, and each item must be in `[-256, 256]`.
- Return the exact number of indexed subsets that sum to the target. The maximum result is `2^24`, which fits in signed 64-bit integers.
- Malformed or out-of-range input returns `-1`.
- The one-dimensional count table updates in the direction that prevents reusing the current item; a zero item doubles every reachable subset count.

## Reviewed TheAlgorithms sources

The pinned [C++ backtracking implementation](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/backtracking/subset_sum.cpp) and its C-Plus-Plus-1 duplicate count subsets by exhaustive masks. This benchmark makes the indexed-subset count semantics explicit and ports them to all nine target languages.

## Workload and verification

[`workload.json`](workload.json) covers empty input, duplicate elements, zero-valued elements, signed values, and validation boundaries. [`benchmarks/verify_subset_sum.py`](../../verify_subset_sum.py) checks every port against an independent Python count oracle over exhaustive short and deterministic randomized cases.

## Implementations

All nine implementations use the shared i64-array/scalar ABI and portable source-level arithmetic.
