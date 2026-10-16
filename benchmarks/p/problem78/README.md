# Project Euler Problem 78

## Contract

For a modulus from 1 through 1,000,000, return the first positive index `n` for which the partition number `p(n)` is divisible by that modulus. The benchmark searches through `n = 55,374`, which includes the pinned default call's first hit; it returns `-1` for invalid moduli or when no hit occurs within that bound.

The ports preserve the source's generalized-pentagonal recurrence. For each `n`, they visit `j = 1, 2, ...`, add terms at `j(3j-1)/2` and `j(3j+1)/2` with alternating signs, and stop when the next generalized pentagonal index exceeds `n`. Residues are normalized to Python's nonnegative modulo range after each term, then the first zero residue is returned before the next partition is stored.

The source examples are `modulus 1 -> 1`, `modulus 9 -> 14`, and the default modulus 1,000,000 -> **55,374**.

Each language exports `int64_t problem78(int64_t modulus)`.

## Workload

[`workload.json`](workload.json) covers both source examples, the default modulus, and invalid moduli. The default uses one sample without warmup because it evaluates the recurrence through the full canonical stopping index.

## TheAlgorithms reference

Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_078/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem78.c](../../../c/p/problem78.c) |
| C3 | [c3/p/problem78.c3](../../../c3/p/problem78.c3) |
| C++ | [cpp/p/problem78.cpp](../../../cpp/p/problem78.cpp) |
| Elisa | [elisa/p/problem78.elisa](../../../elisa/p/problem78.elisa) |
| Nim | [nim/p/problem78.nim](../../../nim/p/problem78.nim) |
| Odin | [odin/p/problem78.odin](../../../odin/p/problem78.odin) |
| Rust | [rust/p/problem78.rs](../../../rust/p/problem78.rs) |
| V | [v/p/problem78.v](../../../v/p/problem78.v) |
| Zig | [zig/p/problem78.zig](../../../zig/p/problem78.zig) |
