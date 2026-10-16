# Jump Game

Given a nonempty array of nonnegative maximum jump lengths, return whether the last index is reachable from index zero. The implementation scans backward, moving the earliest known reachable position left whenever the current index can reach it.

## Contract

The `i64_array_scalar` input is `[n, jumps...]`. `n` is 1..1024 and the packed array contains exactly `n` values, each in 0..1,000,000. Return `1` if the final index is reachable and `0` otherwise. Malformed packing or an out-of-range value returns `-2`.

The nonempty bound excludes the pinned source's `size()-1` underflow on an empty vector. The bounded nonnegative values preserve its `int` inputs and make `index + jump` safe. The result is a reachability boolean; [`jump_game_ii`](../jump_game_ii/README.md) and [`min_number_of_jumps`](../../m/min_number_of_jumps/README.md) return a minimum jump count instead.

## Source

The pinned implementation is C++ `greedy_algorithms/jump_game.cpp` at commit [`fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/greedy_algorithms/jump_game.cpp). Its `can_jump` method sets `lastPos` to the final index, scans indices from right to left, and updates `lastPos` when `i + nums[i] >= lastPos`; it returns whether `lastPos` becomes zero.

[`workload.json`](workload.json) covers reachable and unreachable paths, a singleton, zero jumps, and invalid packed inputs. The nine ports use the shared `i64_array_scalar` ABI.

| Language | Source |
| --- | --- |
| C | [`c/j/jump_game.c`](../../../c/j/jump_game.c) |
| C3 | [`c3/j/jump_game.c3`](../../../c3/j/jump_game.c3) |
| C++ | [`cpp/j/jump_game.cpp`](../../../cpp/j/jump_game.cpp) |
| Elisa | [`elisa/j/jump_game.elisa`](../../../elisa/j/jump_game.elisa) |
| Nim | [`nim/j/jump_game.nim`](../../../nim/j/jump_game.nim) |
| Odin | [`odin/j/jump_game.odin`](../../../odin/j/jump_game.odin) |
| Rust | [`rust/j/jump_game.rs`](../../../rust/j/jump_game.rs) |
| V | [`v/j/jump_game.v`](../../../v/j/jump_game.v) |
| Zig | [`zig/j/jump_game.zig`](../../../zig/j/jump_game.zig) |

Build and verify with the shared scalar ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm jump_game --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/j/jump_game/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms jump_game
```
