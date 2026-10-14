# Coin change

This benchmark finds the minimum number of coins needed to make an amount when each listed denomination may be used without limit.

## Contract

- The read-only input packs `[amount, coin_count, denomination_0, ...]` into a signed 64-bit array.
- `amount` is from 0 through 512; `coin_count` is from 0 through 128; each denomination is from 1 through 4096.
- The packed length must equal `2 + coin_count`. Invalid inputs return `-1`.
- Amount zero returns `0`, including when the denomination list is empty. An amount that cannot be made from the supplied denominations returns `-1`.
- The result is the minimum number of coins. Denominations are unlimited, and repeated denominations do not change the result.
- The ports use amount-ascending dynamic programming with a fixed 513-element table.

## Upstream review

The pinned C++ dynamic-programming, Rust, and Zig files implement minimum-coin change. The Java and JavaScript files include both minimum-coin and combination-counting functions; this benchmark selects their minimum-coin functions. Other files with the same normalized name count combinations, return a chosen coin list, or use a greedy currency-specific strategy. Those behaviors are not aliases of this contract. The two C++ `coin_change_topdown` sources implement the same minimum-coin problem and are cataloged as a filename alias; the local contract defines unreachable results and bounds explicitly.

References: [C++ bottom-up DP](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/coin_change.cpp), [Java DP](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/CoinChange.java), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/coin_change.rs), and [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/dynamicProgramming/coinChange.zig).

## Implementations and verification

Portable implementations use the `i64_array_scalar` C ABI in `c/`, `c3/`, `cpp/`, `elisa/`, `nim/`, `odin/`, `rust/`, `v/`, and `zig/`. `workload.json` covers reachable and unreachable amounts, zero amount, duplicate denominations, a case where greedy choice is suboptimal, and input bounds. `benchmarks/verify_coin_change.py` checks every port against a breadth-first shortest-path oracle, including exhaustive small denomination lists and deterministic generated inputs.

Build with the `i64_array_scalar` ABI family and record with `benchmarks/run_i64_array_scalar.py`.
