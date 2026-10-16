# Project Euler Problem 41: Pandigital Prime

## Contract

For the pinned default `n=7`, and for benchmarked digit counts `n` in `1..=9`, permute the digits `1` through `n` exactly once, keep the prime values, and return the largest. Return `0` when the digit set has no prime permutation. Inputs outside the range return `-1`.

The ports use backtracking to enumerate every permutation, build its integer value, test primality by trial division over `6k ± 1` candidates, and retain the maximum. Since the digit set starts at one, no candidate has a leading zero.

## Workload

[`workload.json`](workload.json) covers every supported digit count and both bounds. The largest pandigital prime over all supported lengths is `7,652,413`, returned for `n = 7`.

## TheAlgorithms references

- Project Euler [Problem 41](https://projecteuler.net/problem=41) defines an `n`-digit pandigital number as using each digit from 1 through `n` exactly once.
- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_041/sol1.py) builds the digit string, enumerates its permutations, tests each with a `6k ± 1` primality routine, and returns the maximum or zero. It documents `n=2 → 0`, `n=4 → 4,231`, and `n=7 → 7,652,413`.

The source's `n=0` call fails when it converts an empty permutation to an integer. For `n > 9`, its digit-string construction introduces multi-character decimal values, so this benchmark restricts the input to the intended single-digit domain `1..=9`.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem41.c](../../../c/p/problem41.c) |
| C3 | [c3/p/problem41.c3](../../../c3/p/problem41.c3) |
| C++ | [cpp/p/problem41.cpp](../../../cpp/p/problem41.cpp) |
| Elisa | [elisa/p/problem41.elisa](../../../elisa/p/problem41.elisa) |
| Nim | [nim/p/problem41.nim](../../../nim/p/problem41.nim) |
| Odin | [odin/p/problem41.odin](../../../odin/p/problem41.odin) |
| Rust | [rust/p/problem41.rs](../../../rust/p/problem41.rs) |
| V | [v/p/problem41.v](../../../v/p/problem41.v) |
| Zig | [zig/p/problem41.zig](../../../zig/p/problem41.zig) |
