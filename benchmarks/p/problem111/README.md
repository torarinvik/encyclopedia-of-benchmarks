# Project Euler Problem 111: Primes with Runs

## Contract

Given `n` from 1,000 through 10,000,000,000, return the sum produced by the pinned Python `solution(n)`. The source uses the decimal length of `n` to determine the candidate width (`len(str(n)) - 1`) and sieves primes through `int(sqrt(n)) + 1`; `n` is a width selector rather than an inclusive candidate limit. Inputs outside the bounded source domain return -1.

For each repeated digit, the source first considers the zero-run candidates for digit 0, then candidates with one changed digit for digits 1 through 9. It records which digits produce a prime in that pass; only when none do, it considers candidates with two changed digits. The ports preserve these loops, leading-zero handling, and sieve bound, using an integer square root to stop divisibility checks early. They also preserve the source result when a candidate equals a generated sieve prime: the source scans the full prime list and rejects that value as divisible by itself. The workload includes the 3-digit-width case where this changes the result for 11. The pinned Python source returns **31283** for `n=1000` and **273700** for `n=10000`. Its default/canonical input `n=10000000000` returns **612407567715**.

## Workload

[`workload.json`](workload.json) covers the lower-bound sieve edge, the documented example, the canonical 10-digit search, and invalid bounds.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_111/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem111.c](../../../c/p/problem111.c) |
| C3 | [c3/p/problem111.c3](../../../c3/p/problem111.c3) |
| C++ | [cpp/p/problem111.cpp](../../../cpp/p/problem111.cpp) |
| Elisa | [elisa/p/problem111.elisa](../../../elisa/p/problem111.elisa) |
| Nim | [nim/p/problem111.nim](../../../nim/p/problem111.nim) |
| Odin | [odin/p/problem111.odin](../../../odin/p/problem111.odin) |
| Rust | [rust/p/problem111.rs](../../../rust/p/problem111.rs) |
| V | [v/p/problem111.v](../../../v/p/problem111.v) |
| Zig | [zig/p/problem111.zig](../../../zig/p/problem111.zig) |
