# Project Euler Problem 234: Semidivisible Numbers

## Contract

Given a nonnegative limit, return the sum of semidivisible integers not exceeding it, where the lower and upper prime square roots are the adjacent primes around the integer square root. A number is semidivisible when exactly one of those primes divides it. Inputs through the pinned limit 999966663333 are supported; negative values and larger limits return -1.

The ports preserve the pinned source's adjacent-prime interval traversal and inclusion-exclusion: add multiples of the lower prime and upper prime in each interval between their squares, then remove twice the multiples of their product. A sieve supplies primes through `floor(sqrt(limit)) + 99`, matching the source's bound. The source example results are 30 for limit 15, 34825 for 1000, 1134942 for 10000, and 36393008 for 100000. The canonical result at 999966663333 is **1259187438574927161**.

## Workload

[`workload.json`](workload.json) covers zero, small interval boundaries, the documented examples, the canonical limit, and invalid bounds.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_234/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem234.c](../../../c/p/problem234.c) |
| C3 | [c3/p/problem234.c3](../../../c3/p/problem234.c3) |
| C++ | [cpp/p/problem234.cpp](../../../cpp/p/problem234.cpp) |
| Elisa | [elisa/p/problem234.elisa](../../../elisa/p/problem234.elisa) |
| Nim | [nim/p/problem234.nim](../../../nim/p/problem234.nim) |
| Odin | [odin/p/problem234.odin](../../../odin/p/problem234.odin) |
| Rust | [rust/p/problem234.rs](../../../rust/p/problem234.rs) |
| V | [v/p/problem234.v](../../../v/p/problem234.v) |
| Zig | [zig/p/problem234.zig](../../../zig/p/problem234.zig) |
