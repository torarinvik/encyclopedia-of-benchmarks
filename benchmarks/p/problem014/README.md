# Project Euler Problem 014

## Contract

This package ports `findLongestCollatzSequence` from TheAlgorithms/JavaScript
Project Euler Problem 014. For an input limit in `1..=1,000,000`, examine
starting values `2 <= start < limit` and return the start with the longest
Collatz sequence. The sequence length counts both its starting term and its
terminal `1`. The initial best start and length are both `1`, so limits 1 and
2 return 1. Strictly longer sequences replace the best result, which preserves
the smallest start when lengths tie. Invalid limits return `-1`.

The pinned JavaScript implementation uses Number arithmetic. These ports
preserve its exact-integer behavior by rejecting a trajectory before an odd
step that would exceed `2^53 - 1`, and reject trajectories longer than 10,000
terms. The supported limits terminate within those guards.

## Workload

[`workload.json`](workload.json) includes empty candidate ranges, a trajectory
that rises above the limit, a limit of 16 where start 9 has the longest chain,
a representative limit, the canonical one-million limit, and invalid signed
64-bit values. The million case uses one repetition per sample because it
evaluates nearly one million starting values.

## TheAlgorithms reference

- JavaScript [`findLongestCollatzSequence`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Project-Euler/Problem014.js) iterates from 2 up to, but not including, the provided limit.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem014.c](../../../c/p/problem014.c) |
| C3 | [c3/p/problem014.c3](../../../c3/p/problem014.c3) |
| C++ | [cpp/p/problem014.cpp](../../../cpp/p/problem014.cpp) |
| Elisa | [elisa/p/problem014.elisa](../../../elisa/p/problem014.elisa) |
| Nim | [nim/p/problem014.nim](../../../nim/p/problem014.nim) |
| Odin | [odin/p/problem014.odin](../../../odin/p/problem014.odin) |
| Rust | [rust/p/problem014.rs](../../../rust/p/problem014.rs) |
| V | [v/p/problem014.v](../../../v/p/problem014.v) |
| Zig | [zig/p/problem014.zig](../../../zig/p/problem014.zig) |
