# Maximum sum of non-adjacent values

This benchmark returns the largest sum obtainable by selecting values with no two selected positions adjacent. Selecting no values is allowed, so the result is never negative.

## Contract

- Input uses `i64_array_scalar` with the array values passed directly as a signed 64-bit sequence.
- The array length is 1 through 100,000; each value is in `[0, 10,000]`.
- Invalid input returns `INT64_MIN`.
- The output is the maximum sum of a subset with no adjacent indices. Zero-valued inputs are valid, and the empty selection contributes zero.
- The ports use the constant-space recurrence: at each element, compare the previous best excluding it with the current value plus the best through the index before the previous one.
- The maximum result is 500,000,000 under these bounds, so it fits the signed 32-bit arithmetic used by the Java source.

## Upstream review

The pinned Python `maximum_non_adjacent_sum`, JavaScript `maximumNonAdjacentSum`, and Java `getMaxSumApproach2` implement the same rolling recurrence. The Java source also provides a table-based version with the same output. C++ `houseRobber`, JavaScript `houseRobber`, and Ruby `house_robber` are aliases for this operation on the shared nonnegative domain. The shared contract excludes negative values because the Java source returns a negative singleton for a one-element negative array, while the Python and JavaScript recurrence allows selecting nothing. It also excludes empty arrays because the JavaScript source's empty check is ineffective and returns a non-number value.

References: [Python `max_non_adjacent_sum.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/max_non_adjacent_sum.py), [JavaScript `MaxNonAdjacentSum.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/MaxNonAdjacentSum.js), [Java `MaximumSumOfNonAdjacentElements.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/MaximumSumOfNonAdjacentElements.java), [C++ `house_robber.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/house_robber.cpp), [C++-1 `house_robber.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/dynamic_programming/house_robber.cpp), [JavaScript `HouseRobber.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/Sliding-Window/HouseRobber.js), and [Ruby `house_robber.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/dynamic_programming/house_robber.rb).

## Implementations

The exported C ABI is `int64_t max_non_adjacent_sum(const int64_t *values, size_t length)`. Implementations are provided in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig. `workload.json` includes upstream examples, zero values, singleton arrays, and invalid bounds.

The source-backed oracle is implemented in `benchmarks/run_i64_array_scalar.py`.
