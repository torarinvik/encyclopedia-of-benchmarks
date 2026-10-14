# Recursive 0/1 knapsack

Solve the 0/1 knapsack problem with the direct recursive include-or-exclude recurrence. Each item may be used at most once. This benchmark keeps the recursive algorithm distinct from the bottom-up tabulation benchmark so their runtime and call-stack behavior can be compared.

## Contract

- Input is a signed 64-bit array [capacity, item_count, weight_0, value_0, ...].
- Capacity is 0 through 512; item count is 0 through 16.
- Item weights are 1 through 4,096; values are 0 through 1,000,000,000.
- Return the greatest total value whose total weight does not exceed capacity.
- Malformed or out-of-range inputs return -1.

The item-count limit bounds the direct recurrence to at most 2^16 leaves. Weights are positive, matching the source base case at zero capacity. No memoization or machine-specific instructions are used.

## Workload and verification

The workload covers empty input, zero capacity, exact fits, overweight items, a combination that beats individual items, a one-use regression, and the maximum item count. verify_01knapsack_recursive.py checks the recursive ports against an independent bottom-up dynamic-programming oracle, exhaustive short sequences, deterministic random cases, and malformed arrays.

## Reviewed TheAlgorithms source

[Dart 01knapsack_recursive.dart](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/dynamic_programming/01knapsack_recursive.dart) uses the direct include-or-exclude recursion without memoization.

## Implementations

All nine portable implementations use the shared i64-array/scalar ABI. The files are in the 0-9 folder for each language.
