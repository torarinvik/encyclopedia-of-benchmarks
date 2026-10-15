# Power Sum

Count the ways to write a target as a sum of distinct positive integers raised to a fixed power. The search considers bases in increasing order. At each base it explores including that power before skipping it, so each selected set of bases is counted once.

## Contract

- The read-only signed 64-bit input packs `[target, power]`.
- The target is from 1 through 1,000. The power is from 2 through 10.
- Return the number of subsets of positive integer bases whose `power`-th powers sum to `target`.
- Malformed or out-of-domain input returns `-1`.
- The bounds match the Python source constraints. At most 31 positive bases have squares at most 1,000; a valid subset has at most 13 terms because `1² + … + 14²` already exceeds 1,000. Thus even the loose count bound `sum(C(31, k), k=0..13) < 2^30` fits Java's signed `int` return type. The first power above a valid target is at most `3^9 = 19,683`, so evaluated terms also fit signed `int`. These bounds limit recursive depth and work.
- The Java method's `(target, power) = (0, 0)` special case is outside this shared domain.

## Workload

[`workload.json`](workload.json) covers one-term sums, multi-term square and cube sums, targets with no representation, the largest target with a high power, and invalid inputs.

## Reviewed sources

- [Java `PowerSum.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/backtracking/PowerSum.java) — recursively tries the current base's power, then skips the base.
- [Python `power_sum.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/power_sum.py) — performs the same include/skip search and states the target and power bounds used here.

This counts subsets of the positive bases, with each base usable at most once. It differs from `combination_sum_iv`, which counts ordered sequences over a supplied denomination list and permits reuse, and from `subset_sum_count`, which chooses from an explicit input array.

## Implementations

The nine ports use the shared `i64_array_scalar` ABI. Their source files are in the `p` folder for each language.

The source-backed oracle is implemented in `benchmarks/run_i64_array_scalar.py`.
