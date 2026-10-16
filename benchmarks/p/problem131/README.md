# Project Euler Problem 131: prime cube partnership

## Contract

For an exclusive limit from 0 through 1,000,000, return the count of prime values in the candidate sequence below that limit. The pinned source starts with candidate 7 and cube index 1; each loop checks primality, increments the index, then adds six times the new index to the candidate. Thus the sequence begins 7, 19, 37, 61, and the bound is strict. Limits outside the benchmark domain return `-1`.

Primality follows the source helper: values below 2 are not prime, and trial divisors are checked in ascending order from 2 through the integer square root. The source example `solution(100)` returns **4**. Its default bound of 1,000,000 returns **173**.

## Workload

[`workload.json`](workload.json) includes the strict candidate boundary, source example, canonical result, and invalid limits.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_131/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem131.c](../../../c/p/problem131.c) |
| C3 | [c3/p/problem131.c3](../../../c3/p/problem131.c3) |
| C++ | [cpp/p/problem131.cpp](../../../cpp/p/problem131.cpp) |
| Elisa | [elisa/p/problem131.elisa](../../../elisa/p/problem131.elisa) |
| Nim | [nim/p/problem131.nim](../../../nim/p/problem131.nim) |
| Odin | [odin/p/problem131.odin](../../../odin/p/problem131.odin) |
| Rust | [rust/p/problem131.rs](../../../rust/p/problem131.rs) |
| V | [v/p/problem131.v](../../../v/p/problem131.v) |
| Zig | [zig/p/problem131.zig](../../../zig/p/problem131.zig) |
