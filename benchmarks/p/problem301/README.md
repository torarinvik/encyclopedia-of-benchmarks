# Project Euler Problem 301: Nim

## Contract

For an exponent from 0 through 30, preserve the pinned source's integer result; inputs outside the benchmark domain return `-1`. The mathematical count of losing three-heap Nim positions `(n, 2n, 3n)` for `1 <= n <= 2^exponent` is Fibonacci at index `exponent + 2`, but the pinned source differs for odd exponents.

The pinned source computes `(phi^(exponent+2) - (phi-1)^(exponent+2)) / sqrt(5)` and converts it to an integer. Since `(phi-1)` is positive, the source expression differs from the standard Binet formula for odd exponents: it returns `F(exponent+2)-1`. The ports use an integer Fibonacci recurrence and apply that source-specific correction for odd exponents.

The source examples return **1** for exponent 0, **3** for exponent 2, and **144** for exponent 10. Odd exponents 1, 3, and 29 return **1**, **4**, and **1,346,268**. Exponent 30 returns **2,178,309**.

## Workload

[`workload.json`](workload.json) covers the source examples, canonical exponent, and invalid values.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_301/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem301.c](../../../c/p/problem301.c) |
| C3 | [c3/p/problem301.c3](../../../c3/p/problem301.c3) |
| C++ | [cpp/p/problem301.cpp](../../../cpp/p/problem301.cpp) |
| Elisa | [elisa/p/problem301.elisa](../../../elisa/p/problem301.elisa) |
| Nim | [nim/p/problem301.nim](../../../nim/p/problem301.nim) |
| Odin | [odin/p/problem301.odin](../../../odin/p/problem301.odin) |
| Rust | [rust/p/problem301.rs](../../../rust/p/problem301.rs) |
| V | [v/p/problem301.v](../../../v/p/problem301.v) |
| Zig | [zig/p/problem301.zig](../../../zig/p/problem301.zig) |
