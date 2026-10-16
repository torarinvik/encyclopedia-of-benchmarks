# Dynamic coin change solver

The pinned C# solver returns the denominations actually selected, in order. Its backward-induction rule is distinct from [`coin_change`](../../c/coin_change/README.md), which returns the minimum number of coins, and [`coinchange`](../../c/coinchange/README.md), which counts combinations. For example, with coins `[1,4,5]` and amount 12, this solver selects `[5,5,1,1]`; a minimum-count solver can make the amount in three coins.

## Contract

Input is `[amount, coin_count, coin_0, ..., coin_(coin_count-1)]`. Amount is 1 through 18; there are 1 through 9 distinct denominations, each 1 through 9, and denomination 1 is required. Invalid values or shape return `-1`.

The source copies and sorts denominations descending, then for each current amount lists the remainders produced by each denomination not exceeding it. `GetMinimalNextCoin` chooses remainder `r` whose own list has the smallest minimum remainder; it retains the first remainder on ties and returns zero immediately when the current amount itself is a denomination. `MakeCoinChangeDynamic` repeats this until zero and returns the selected coin list.

The scalar ABI returns the exact ordered list as decimal digit concatenation. Since each selected denomination is one digit from 1 to 9, leading-zero ambiguity is impossible; amount≤18 bounds the sequence to at most 18 digits, within signed 64-bit. Example: `[5,5,1,1]` is `5511`. Input denomination order has no effect because the source sorts a copy.

The pinned [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Problems/DynamicProgramming/CoinChange/DynamicCoinChangeSolver.cs) documents this as a minimal-coin solver, but its executable selection rule can return a longer sequence than an optimal minimum-count solution. [`workload.json`](workload.json) covers backward-induction choices, that non-optimal result, tie ordering, denomination order independence, bounds, and malformed coin arrays. The independent oracle is [`dynamic_coin_change_solver_oracle.py`](../../dynamic_coin_change_solver_oracle.py).

## Ports

| Language | Source |
|---|---|
| C | [`c/d/dynamic_coin_change_solver.c`](../../../c/dynamic_coin_change_solver.c) |
| C3 | [`c3/d/dynamic_coin_change_solver.c3`](../../../c3/d/dynamic_coin_change_solver.c3) |
| C++ | [`cpp/d/dynamic_coin_change_solver.cpp`](../../../cpp/d/dynamic_coin_change_solver.cpp) |
| Elisa | [`elisa/d/dynamic_coin_change_solver.elisa`](../../../elisa/d/dynamic_coin_change_solver.elisa) |
| Nim | [`nim/d/dynamic_coin_change_solver.nim`](../../../nim/d/dynamic_coin_change_solver.nim) |
| Odin | [`odin/d/dynamic_coin_change_solver.odin`](../../../odin/d/dynamic_coin_change_solver.odin) |
| Rust | [`rust/d/dynamic_coin_change_solver.rs`](../../../rust/d/dynamic_coin_change_solver.rs) |
| V | [`v/d/dynamic_coin_change_solver.v`](../../../v/d/dynamic_coin_change_solver.v) |
| Zig | [`zig/d/dynamic_coin_change_solver.zig`](../../../zig/d/dynamic_coin_change_solver.zig) |

Run `python3 benchmarks/verify_i64_array_scalar.py --algorithms dynamic_coin_change_solver` to validate all ports and workload records.
