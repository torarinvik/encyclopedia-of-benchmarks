# Project Euler Problem 36: Double-base Palindromes

## Contract

For an exclusive limit of `0..=1,000,000`, sum every positive integer `n < limit` whose base-10 representation and base-2 representation are both palindromes. Representations have no leading zeroes. A limit of zero or one returns zero; limits outside the range return `-1`.

The ports scan values from one up to, but not including, the limit. They reverse the decimal digits and binary digits numerically and compare each reversed value with the original. The binary check therefore uses only the significant bits and never treats leading zeroes as digits.

## Workload

[`workload.json`](workload.json) covers empty ranges, the source examples at limits 2, 10, 100, 1,000, 100,000, 500,000, and 1,000,000, the inclusion boundary around 585, and invalid bounds. The canonical exclusive limit of 1,000,000 returns `872,187`.

## TheAlgorithms references

- Project Euler [Problem 36](https://projecteuler.net/problem=36) asks for the sum below one million and specifies that neither representation may have leading zeroes.
- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_036/sol1.py) scans `range(1, n)`, checking the decimal string and the binary digits from `bin(n)`. Its default limit is 1,000,000 and it documents the same canonical sum.

The source returns zero for every `n <= 1` because the scan range is empty. This benchmark preserves that behavior for zero and one, while rejecting negative limits and limits above one million.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem36.c](../../../c/p/problem36.c) |
| C3 | [c3/p/problem36.c3](../../../c3/p/problem36.c3) |
| C++ | [cpp/p/problem36.cpp](../../../cpp/p/problem36.cpp) |
| Elisa | [elisa/p/problem36.elisa](../../../elisa/p/problem36.elisa) |
| Nim | [nim/p/problem36.nim](../../../nim/p/problem36.nim) |
| Odin | [odin/p/problem36.odin](../../../odin/p/problem36.odin) |
| Rust | [rust/p/problem36.rs](../../../rust/p/problem36.rs) |
| V | [v/p/problem36.v](../../../v/p/problem36.v) |
| Zig | [zig/p/problem36.zig](../../../zig/p/problem36.zig) |
