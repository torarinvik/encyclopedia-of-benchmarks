# Minimum Squares to Represent a Number

Return the minimum number of perfect-square terms whose sum is the input. For positive `n`, the pinned Python source fills a dynamic-programming table with `dp[0] = 0` and `dp[i] = 1 + min(dp[i - j²])` for every `j² <= i`.

## Contract

- Inputs from `0` through `4096` are supported.
- The source explicitly returns `1` for input zero, even though the table's `dp[0]` base value is `0`. Ports preserve that public behavior.
- Negative inputs raise `ValueError` in Python; the scalar benchmark maps them to `-1`. Inputs above the bound also return `-1` as a contract error.
- Positive inputs return the minimum number of square terms, not whether the input is itself a square.
- The implementations preserve the source's bottom-up table recurrence. The bound keeps the fixed table small and the nested square loop practical.
- The function uses the unary signed 64-bit scalar ABI and has `O(n√n)` time and `O(n)` space complexity.

The source is the pinned [TheAlgorithms/Python `minimum_squares_to_represent_a_number.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/minimum_squares_to_represent_a_number.py). This differs from `perfect_square`, which is a predicate, and `sum_of_squares`, which sums the squares of a range of integers.

Build one port with `python3 benchmarks/build_scalar.py --algorithm minimum_squares_to_represent_a_number --language LANGUAGE`. The build manifest is written to `build/scalar/m/minimum_squares_to_represent_a_number/LANGUAGE/build.json`; the workload uses the standard scalar runner interface in [`benchmarks/run_scalar.py`](../../run_scalar.py).
