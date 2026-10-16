# Project Euler Problem 32: Pandigital products

## Contract

Enumerate the permutations of digits 1 through 9. For each permutation, check the two possible product layouts `2-digit × 3-digit = 4-digit` and `1-digit × 4-digit = 4-digit`. Sum each matching four-digit product once, even if it has more than one multiplicative identity. The result is 45,228.

The source operation has a fixed digit set and no arguments. A zero-valued placeholder is accepted for the shared scalar runner ABI; nonzero inputs return `-1`. Each port walks all 9! permutations and tracks distinct products in a bounded 10,000-entry set.

## Source review

The pinned Python [`sol32`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_032/sol32.py) uses the same two digit partitions, tests each permutation of `123456789`, and deduplicates products before summing. Its documented output is 45,228.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem32.c](../../../c/p/problem32.c) |
| C3 | [c3/p/problem32.c3](../../../c3/p/problem32.c3) |
| C++ | [cpp/p/problem32.cpp](../../../cpp/p/problem32.cpp) |
| Elisa | [elisa/p/problem32.elisa](../../../elisa/p/problem32.elisa) |
| Nim | [nim/p/problem32.nim](../../../nim/p/problem32.nim) |
| Odin | [odin/p/problem32.odin](../../../odin/p/problem32.odin) |
| Rust | [rust/p/problem32.rs](../../../rust/p/problem32.rs) |
| V | [v/p/problem32.v](../../../v/p/problem32.v) |
| Zig | [zig/p/problem32.zig](../../../zig/p/problem32.zig) |
