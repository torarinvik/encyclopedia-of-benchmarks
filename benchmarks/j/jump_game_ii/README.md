# Jump Game II

This benchmark ports C LeetCode 45's breadth-first search over reachable indices. It tracks visited positions so each index enters the queue at most once and returns the first BFS distance that reaches the final index.

## Contract

- Input contains 1 to 1,024 signed 64-bit array values, each in the inclusive range 0 through the array length.
- Invalid input or an unreachable final index returns `-1`.
- A one-element input returns `0`; otherwise the result is the minimum number of jumps to the last index.
- The implementation uses a FIFO index queue, visited flags, and per-index BFS distance values. It uses generic scalar operations and no architecture-specific instructions.
- C ABI entry point: `int64_t jump_game_ii(const int64_t *values, size_t length)`.

The numeric upstream filename `45.c` is cataloged under the alphabetic algorithm name `jump_game_ii`. The benchmark preserves the source's BFS strategy while avoiding its redundant revisits of an index's self-edge.

Run `python3 benchmarks/verify_jump_game_ii.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to check all nine ports against exhaustive short arrays, seeded random inputs, maximum-length cases, signed and range validation, unreachable cases, and workload records.

## Implementations

The portable ports are [`c/j/jump_game_ii.c`](../../../c/j/jump_game_ii.c), [`c3/j/jump_game_ii.c3`](../../../c3/j/jump_game_ii.c3), [`cpp/j/jump_game_ii.cpp`](../../../cpp/j/jump_game_ii.cpp), [`elisa/j/jump_game_ii.elisa`](../../../elisa/j/jump_game_ii.elisa), [`nim/j/jump_game_ii.nim`](../../../nim/j/jump_game_ii.nim), [`odin/j/jump_game_ii.odin`](../../../odin/j/jump_game_ii.odin), [`rust/j/jump_game_ii.rs`](../../../rust/j/jump_game_ii.rs), [`v/j/jump_game_ii.v`](../../../v/j/jump_game_ii.v), and [`zig/j/jump_game_ii.zig`](../../../zig/j/jump_game_ii.zig).

## Upstream reference

- [TheAlgorithms/C LeetCode 45](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/45.c)
