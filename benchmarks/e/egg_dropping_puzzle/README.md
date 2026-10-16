# Egg Dropping Puzzle

This benchmark ports the pinned C++ `eggDrop(eggs, floors)` dynamic program. It returns the minimum number of drops needed in the worst case to determine the threshold floor, given the number of eggs and test floors.

## Contract

The `i64_array_scalar` input is exactly `[eggs, floors]`. `eggs` is in `[1, 8]`; `floors` is in `[1, 32]`. The result is the minimum `trials` satisfying the source recurrence:

`dp[e][f] = 1 + min(max(dp[e-1][x-1], dp[e][f-x]))` for `1 <= x <= f`, with `dp[e][1] = 1` and `dp[1][f] = f`.

Invalid shape or out-of-range inputs return `-1`. The bounds keep the source's integer result safe and limit the quadratic work per egg count of the recurrence.

## Source and workload

The source is [TheAlgorithms/C-Plus-Plus `egg_dropping_puzzle.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/egg_dropping_puzzle.cpp), with the same source in [C-Plus-Plus-1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/dynamic_programming/egg_dropping_puzzle.cpp). Its `eggDrop` function uses an eggs-by-floors table and tries every possible drop floor. The contract excludes zero eggs and zero floors because the pinned function's base-case assignments index `eggFloor[1]` even when either dimension is zero.

[`workload.json`](workload.json) covers one-egg linear behavior, two-egg cases, known minimax cases, upper bounds, and malformed or out-of-range inputs. [`egg_dropping_puzzle_oracle.py`](../../egg_dropping_puzzle_oracle.py) uses a move-count recurrence to calculate expected results independently from the source's table recurrence.

Build with the shared `i64_array_scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm egg_dropping_puzzle --language rust
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/e/egg_dropping_puzzle.c`](../../../c/e/egg_dropping_puzzle.c) |
| C3 | [`c3/e/egg_dropping_puzzle.c3`](../../../c3/e/egg_dropping_puzzle.c3) |
| C++ | [`cpp/e/egg_dropping_puzzle.cpp`](../../../cpp/e/egg_dropping_puzzle.cpp) |
| Elisa | [`elisa/e/egg_dropping_puzzle.elisa`](../../../elisa/e/egg_dropping_puzzle.elisa) |
| Nim | [`nim/e/egg_dropping_puzzle.nim`](../../../nim/e/egg_dropping_puzzle.nim) |
| Odin | [`odin/e/egg_dropping_puzzle.odin`](../../../odin/e/egg_dropping_puzzle.odin) |
| Rust | [`rust/e/egg_dropping_puzzle.rs`](../../../rust/e/egg_dropping_puzzle.rs) |
| V | [`v/e/egg_dropping_puzzle.v`](../../../v/e/egg_dropping_puzzle.v) |
| Zig | [`zig/e/egg_dropping_puzzle.zig`](../../../zig/e/egg_dropping_puzzle.zig) |
