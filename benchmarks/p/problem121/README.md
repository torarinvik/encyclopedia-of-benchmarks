# Project Euler Problem 121

## Contract

For 1 through 15 turns, return the maximum whole-pound prize fund, including the player's £1 entry, for which the player is not expected to lose money when a win requires more blue than red discs. Invalid turn counts return `-1`.

The ports enumerate the pinned source's red/blue sequences and skip those without a strict blue majority. Each sequence has denominator `(turns + 1)!`; a red draw on one-based turn `k` contributes numerator factor `k`, while a blue draw contributes 1; each turn has denominator `k + 1`. Summing these integer weights gives the exact winning probability. The returned prize is the floor of its reciprocal, matching the source's `int(1 / total_prob)` threshold without floating-point boundary drift. All weights fit signed 64-bit integers at the 15-turn bound.

The source examples return **10** for four turns and **225** for ten turns. The canonical 15-turn answer is **2269**.

## Workload

[`workload.json`](workload.json) covers the one-turn case, the source examples, the canonical 15-turn case, and invalid turn counts.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_121/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem121.c](../../../c/p/problem121.c) |
| C3 | [c3/p/problem121.c3](../../../c3/p/problem121.c3) |
| C++ | [cpp/p/problem121.cpp](../../../cpp/p/problem121.cpp) |
| Elisa | [elisa/p/problem121.elisa](../../../elisa/p/problem121.elisa) |
| Nim | [nim/p/problem121.nim](../../../nim/p/problem121.nim) |
| Odin | [odin/p/problem121.odin](../../../odin/p/problem121.odin) |
| Rust | [rust/p/problem121.rs](../../../rust/p/problem121.rs) |
| V | [v/p/problem121.v](../../../v/p/problem121.v) |
| Zig | [zig/p/problem121.zig](../../../zig/p/problem121.zig) |
