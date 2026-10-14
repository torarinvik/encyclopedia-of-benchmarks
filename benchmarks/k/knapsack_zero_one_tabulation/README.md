# 0/1 knapsack tabulation

This benchmark solves the 0/1 knapsack problem with bottom-up dynamic programming. Each item can be selected at most once, and the total weight may not exceed the capacity. The recurrence for item `i` and capacity `c` is the maximum of the previous row at `c` and the item's value plus the previous row at `c - weight[i]`. The ports keep one row and visit capacities in descending order, which preserves the previous-row recurrence while using O(capacity) storage.

## Contract

- The read-only signed 64-bit input packs the capacity and item pairs as `[capacity, item_count, weight_0, value_0, ...]`.
- Capacity is from 0 through 512, and item count is from 0 through 128.
- Each weight is from 1 through 4096. Each value is from 0 through 1,000,000,000.
- The result is the maximum achievable value. Malformed inputs return `-1`.
- The limits keep every intermediate sum within signed 64-bit range. Implementations use portable integer operations and allocate no memory.

## Workload and verification

[`workload.json`](workload.json) includes empty sets, zero capacity, exact fits, overweight items, a combination that beats every single item, a one-use regression case, capacity 512, and the maximum item value. The verifier also compares the ports with an independent dynamic-programming oracle on exhaustive small cases, deterministic random inputs, and malformed encodings.

## Reviewed TheAlgorithms sources

- [C++ `0_1_knapsack.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/0_1_knapsack.cpp) — tabulated two-dimensional recurrence.
- [Java `KnapsackZeroOneTabulation.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/KnapsackZeroOneTabulation.java) — bottom-up table.
- [Kotlin `ZeroOneKnapsackProblem.kt`](https://github.com/TheAlgorithms/Kotlin/blob/b913c1d85c972fd1e679c5d832d6458b21be8fb0/src/main/kotlin/dynamicProgramming/ZeroOneKnapsackProblem.kt) — bottom-up table.

The C++ and Kotlin filename candidates are aliases of the Java tabulation benchmark. Recursive and memoized knapsack variants, as well as fractional and unbounded knapsack, remain distinct candidates.

## Implementations

The nine portable ports use the shared `i64_array_scalar` ABI. Their source files are in the `k` folder for each language.
