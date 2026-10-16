# Project Euler Problem 26

## Contract

Given an inclusive denominator limit `digit` in `0..=1000`, return the denominator that first achieves the largest number of distinct remainders before a repeat while generating `1/d` in base ten for each `d` from 1 through `digit`. The ports preserve the pinned Python routine's score: it counts the whole distinct-remainder prefix, including any nonrepeating prefix and a terminal zero, and examines at most `digit` remainders per denominator. A denominator whose repeat is not observed within that bound does not update the winner. Inputs outside the range return `-1`. An empty denominator range returns the source's initial result, `1`.

Each language exports a C ABI function:

```c
int64_t problem26(int64_t digit);
```

The bounded bitmap lookup keeps the Python source's remainder sequence and result while limiting each denominator to at most `digit` transitions. It avoids the source list's linear membership scan.

## Workload

[`workload.json`](workload.json) covers empty and small ranges, the published examples for limits 10 and 100, the canonical limit 1000, and invalid inputs. The verifier uses a separate map-based oracle and the benchmark runner checks workload expectations against the source recurrence.

## Source review

The pinned Python implementation accepts `numerator` and `digit`, starts each remainder sequence at `numerator`, and scans the denominator range inclusively. This package fixes `numerator=1`, matching the unit-fraction problem. The C source is a standalone program fixed to denominators 2 through 1999. It also calls `bsearch` on remainders in generation order without sorting them, so it does not implement the same parameterized contract and is not used as a semantic reference.

## TheAlgorithms references

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_026/sol1.py)
- C [`sol1.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/project_euler/problem_26/sol1.c)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem26.c](../../../c/p/problem26.c) |
| C3 | [c3/p/problem26.c3](../../../c3/p/problem26.c3) |
| C++ | [cpp/p/problem26.cpp](../../../cpp/p/problem26.cpp) |
| Elisa | [elisa/p/problem26.elisa](../../../elisa/p/problem26.elisa) |
| Nim | [nim/p/problem26.nim](../../../nim/p/problem26.nim) |
| Odin | [odin/p/problem26.odin](../../../odin/p/problem26.odin) |
| Rust | [rust/p/problem26.rs](../../../rust/p/problem26.rs) |
| V | [v/p/problem26.v](../../../v/p/problem26.v) |
| Zig | [zig/p/problem26.zig](../../../zig/p/problem26.zig) |
