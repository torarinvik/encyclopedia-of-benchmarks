# Brute-force 0/1 knapsack

Solve 0/1 knapsack with the pinned Java source's direct recursive include/exclude recurrence. Each item is considered at most once. This is distinct from the existing [`knapsack_zero_one_tabulation`](../../k/knapsack_zero_one_tabulation/README.md) benchmark, which uses bottom-up dynamic programming.

## Contract

The `i64_array_scalar` input packs `[capacity, item_count, weight_0, value_0, ...]`. Capacity is in `[0, 512]`, item count in `[0, 14]`, each weight in `[1, 4096]`, and each value in `[0, 100000000]`. The input length must equal `2 + 2 * item_count`. Invalid input returns `-1`.

The ports follow the source base cases (`item_count == 0` or `capacity == 0` returns zero), skip items that do not fit, and otherwise recurse into both exclusion and inclusion branches. There is no memoization. The bounds keep the exponential workload manageable and keep the result within the source Java `int` range.

## Workload and build

[`workload.json`](workload.json) covers empty sets, zero capacity, exact fits, combinations, no reuse, malformed inputs, and the maximum item count.

The shared `i64_array_scalar` runner validates workload results with a direct recursive include/exclude oracle using the same item bound.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm brute_force_knapsack --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/b/brute_force_knapsack/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/b/brute_force_knapsack.c`](../../../c/b/brute_force_knapsack.c) |
| C3 | [`c3/b/brute_force_knapsack.c3`](../../../c3/b/brute_force_knapsack.c3) |
| C++ | [`cpp/b/brute_force_knapsack.cpp`](../../../cpp/b/brute_force_knapsack.cpp) |
| Elisa | [`elisa/b/brute_force_knapsack.elisa`](../../../elisa/b/brute_force_knapsack.elisa) |
| Nim | [`nim/b/brute_force_knapsack.nim`](../../../nim/b/brute_force_knapsack.nim) |
| Odin | [`odin/b/brute_force_knapsack.odin`](../../../odin/b/brute_force_knapsack.odin) |
| Rust | [`rust/b/brute_force_knapsack.rs`](../../../rust/b/brute_force_knapsack.rs) |
| V | [`v/b/brute_force_knapsack.v`](../../../v/b/brute_force_knapsack.v) |
| Zig | [`zig/b/brute_force_knapsack.zig`](../../../zig/b/brute_force_knapsack.zig) |

## Pinned source

- Java [`BruteForceKnapsack.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/BruteForceKnapsack.java)
