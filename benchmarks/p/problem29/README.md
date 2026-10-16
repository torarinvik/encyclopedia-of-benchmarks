# Project Euler Problem 29: Distinct powers

## Contract

For a limit `n` in `1..=100`, return the number of distinct exact values `a^b` for every `2 <= a,b <= n`. This preserves the pinned Python source's inclusive domain: it increments `n` once, then iterates `range(2, n + 1)`. Invalid limits return `-1`.

The ports avoid storing large power values. Each base is reduced to its maximal perfect-power form `root^factor`; each term is then represented by the unique pair `(root, factor * b)`. A fixed lookup table counts each pair once. For bases through 100 the maximal factor is at most 6, so the largest key is bounded by 600. This representation is exact: equal integer powers have the same primitive root and total exponent.

## Workload

[`workload.json`](workload.json) covers the empty term set at n=1, one term at n=2, the first four terms at n=3, the statement's 15-term n=5 example, documented n=20 and n=50 results, the canonical n=100 answer 9183, and invalid bounds. The canonical case uses one repetition per sample.

## TheAlgorithms reference

- Python [`solution`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_029/sol1.py) inserts every exact power for `2 <= a,b <= n` into a set and returns the set size.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem29.c](../../../c/p/problem29.c) |
| C3 | [c3/p/problem29.c3](../../../c3/p/problem29.c3) |
| C++ | [cpp/p/problem29.cpp](../../../cpp/p/problem29.cpp) |
| Elisa | [elisa/p/problem29.elisa](../../../elisa/p/problem29.elisa) |
| Nim | [nim/p/problem29.nim](../../../nim/p/problem29.nim) |
| Odin | [odin/p/problem29.odin](../../../odin/p/problem29.odin) |
| Rust | [rust/p/problem29.rs](../../../rust/p/problem29.rs) |
| V | [v/p/problem29.v](../../../v/p/problem29.v) |
| Zig | [zig/p/problem29.zig](../../../zig/p/problem29.zig) |
