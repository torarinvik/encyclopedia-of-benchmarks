# Minimum coin change (greedy)

This package ports the greedy `find_minimum_change` routines from the pinned Python and Rust sources. It repeatedly takes the largest denomination that fits and emits selected coins in descending order. This algorithm can be nonoptimal for arbitrary denomination sets and silently leaves any unrepresented remainder; the benchmark preserves that behavior.

## Contract

- Input is `[target, denomination_count, denominations...]`, all supplied as signed i64 values. The exact length is `2 + denomination_count`; count is 0 through 32, target is -4,096 through 4,096, and denominations must be strictly increasing positive integers from 1 through 4,096. A denomination of 1 is not required.
- For a positive target, denominations are considered from largest to smallest and each is subtracted repeatedly while it fits. The selected values are returned in descending order. For example, target 6 with `[1, 3, 4]` returns `[4, 1, 1]`; target 6 with only `[4]` returns `[4]`, leaving remainder 2 unreported.
- A target at or below zero or an empty denomination list selects no coins. The output still contains the count prefix, so an empty selection is the single i32 value `[0]`.
- Output is a little-endian signed i32 array `[coin_count, selected_values...]`; the ABI return is the number of output bytes written. Maximum output is 16,388 bytes, for 4,096 selected unit coins. Invalid input returns `-1`; a null output buffer or insufficient capacity for valid input returns `-2`. Errors write no output.

The Python source is pinned at [`minimum_coin_change.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/greedy_methods/minimum_coin_change.py). The Rust source is pinned at [`minimum_coin_change.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/greedy/minimum_coin_change.rs). The dynamic-programming algorithm with a similar name is a separate benchmark. See the [workload](workload.json) and [oracle](../../minimum_coin_change_greedy_oracle.py).

| Language | Port |
|---|---|
| C | [minimum_coin_change_greedy.c](../../../c/m/minimum_coin_change_greedy.c) |
| C3 | [minimum_coin_change_greedy.c3](../../../c3/m/minimum_coin_change_greedy.c3) |
| C++ | [minimum_coin_change_greedy.cpp](../../../cpp/m/minimum_coin_change_greedy.cpp) |
| Elisa | [minimum_coin_change_greedy.elisa](../../../elisa/m/minimum_coin_change_greedy.elisa) |
| Nim | [minimum_coin_change_greedy.nim](../../../nim/m/minimum_coin_change_greedy.nim) |
| Odin | [minimum_coin_change_greedy.odin](../../../odin/m/minimum_coin_change_greedy.odin) |
| Rust | [minimum_coin_change_greedy.rs](../../../rust/m/minimum_coin_change_greedy.rs) |
| V | [minimum_coin_change_greedy.v](../../../v/m/minimum_coin_change_greedy.v) |
| Zig | [minimum_coin_change_greedy.zig](../../../zig/m/minimum_coin_change_greedy.zig) |
