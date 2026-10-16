# Project Euler Problem 60

## Contract

The pinned Python source's default call searches for a five-prime set and uses the first 1,000 generated primes in its modulo-3 class-1 list. The list begins with the source's shared seed `3, 7, 13, 19`; subsequent candidates advance by three until prime. Its recursive search visits primes and branches in ascending order, requiring both decimal concatenation orders for every pair to be prime, and returns the first complete set found. The documented default result is **26,033**.

The benchmark exposes the fixed default call through a scalar placeholder: input `0` runs the search and other inputs return `-1`. Each port exports `int64_t problem60(int64_t placeholder)`. The pair cache stores completed compatibility checks for the current call and is cleared on every invocation.

## Workload

[`workload.json`](workload.json) contains the pinned default call and positive and negative invalid placeholders. It uses one sample without warmup because the source search is substantially more expensive than the neighboring fixed-answer Euler packages.

## Source review

The source's `generate_primes(1000, 1)` argument is a count of generated candidates, not a numeric ceiling. The benchmark preserves its initial seed, step-by-three prime generation, ascending recursive branch order, and two-way concatenation check. The source returns the first complete chain reached; the ports preserve that traversal instead of replacing it with a different minimum-sum search.

TheAlgorithms Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_060/sol1.py) documents `solution(5, 1000, 1) -> 26033`.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem60.c](../../../c/p/problem60.c) |
| C3 | [c3/p/problem60.c3](../../../c3/p/problem60.c3) |
| C++ | [cpp/p/problem60.cpp](../../../cpp/p/problem60.cpp) |
| Elisa | [elisa/p/problem60.elisa](../../../elisa/p/problem60.elisa) |
| Nim | [nim/p/problem60.nim](../../../nim/p/problem60.nim) |
| Odin | [odin/p/problem60.odin](../../../odin/p/problem60.odin) |
| Rust | [rust/p/problem60.rs](../../../rust/p/problem60.rs) |
| V | [v/p/problem60.v](../../../v/p/problem60.v) |
| Zig | [zig/p/problem60.zig](../../../zig/p/problem60.zig) |
