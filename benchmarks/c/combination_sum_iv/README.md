# Combination Sum IV

This benchmark counts the ordered sequences of denominations that sum to a target. It follows the pinned Python bottom-up dynamic-programming routine: initialize `dp[0]` to one, visit sums from 1 through the target, and for each sum visit denominations in their input order, adding `dp[sum - denomination]` when the denomination fits. Because the sum loop is outermost, different orderings of the same denominations count as different sequences.

## Contract

- The read-only signed 64-bit input packs `[denomination_count, target, denomination_0, ...]`.
- The packed length must equal `denomination_count + 2`. The count is from 0 through 16, and the target is from 0 through 63.
- Denominations must be pairwise distinct integers from 1 through 63. Positive denominations make the recurrence well-defined, while uniqueness keeps the input domain canonical.
- The result is the number of ordered sequences. The empty sequence contributes one way to make target zero; an unreachable target has zero ways.
- Malformed or out-of-domain input returns `INT64_MIN`.
- At target 63, the result is bounded by the number of integer compositions, at most `2^62`, so all intermediate counts fit signed 64-bit integers.

## Workload

[`workload.json`](workload.json) covers empty denominations, zero and unreachable targets, the source example, input order, denominations larger than the target, and malformed or out-of-domain packed input.

## Reviewed source

- [Python `combination_sum_iv.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/combination_sum_iv.py) — bottom-up routine with sums outermost and source denomination order innermost.

The recursive and memoized functions in that file implement the same ordered-sequence recurrence. The benchmark uses the bottom-up routine as its measured strategy. This algorithm differs from unordered combination-sum counting, where choosing the same denominations in different orders counts once.

## Implementations

The nine portable ports use the shared `i64_array_scalar` ABI. Their source files are in the `c` folder for each language.
