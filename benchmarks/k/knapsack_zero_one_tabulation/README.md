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
- [Go `knapsack.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/dynamic/knapsack.go)
- [Java `Knapsack.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/Knapsack.java)
- [Python `dynamic_programming/knapsack.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/knapsack.py)
- [Python `knapsack/knapsack.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/knapsack/knapsack.py) — defaults to 0/1 and also supports optional unbounded selection.
- [Ruby `knapsack.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/dynamic_programming/knapsack.rb)
- [Rust `knapsack.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/knapsack.rs)
- [Solidity `Knapsack.sol`](https://github.com/TheAlgorithms/Solidity/blob/08cba51fb38e276062b0c9791d7e0ee494ffa903/src/DynamicProgramming/Knapsack.sol)
- [TypeScript `knapsack.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/dynamic_programming/knapsack.ts)
- [Zig `knapsack.zig`](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/dynamicProgramming/knapsack.zig)
- [R `1_knapsack_problem.r` (nested)](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/dynamic_programming/0/0/1_knapsack_problem.r)
- [R `1_knapsack_problem.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/dynamic_programming/0/1_knapsack_problem.r)

The C++ and Kotlin filename candidates, plus R candidate `1_knapsack_problem`, are aliases of the Java tabulation benchmark. The generic `knapsack` candidate is a mixed filename group: its Go, Java, Python, Ruby, Rust, Solidity, TypeScript, and Zig implementations are 0/1 variants and alias this benchmark; its two C++ implementations are fractional knapsack and are listed in the [fractional-knapsack guide](../../f/fractional_knapsack/README.md). The Python `knapsack/knapsack.py` source also exposes an optional unbounded mode. Recursive and memoized knapsack algorithms remain distinct candidates.

## Implementations

The nine portable ports use the shared `i64_array_scalar` ABI. Their source files are in the `k` folder for each language.
