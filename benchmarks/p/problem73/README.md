# Project Euler Problem 73

## Contract

For `max_denominator` from 0 through 12,000, count reduced proper fractions strictly between `1/3` and `1/2` whose denominator is at most the inclusive limit. Invalid inputs return `-1`.

The ports preserve the pinned source's per-denominator bounds. It starts numerators at `floor(d/3)+1`, so the lower endpoint is excluded. For even denominators it advances to an odd numerator and steps by two, since an even numerator cannot be coprime with an even denominator. The upper bound is `(d+1)//2` exclusive, which excludes `1/2` for even denominators and includes every numerator below it for odd denominators. A Euclidean GCD keeps only reduced fractions.

The source examples are `4 -> 0`, `5 -> 1`, and `8 -> 3`; the default limit 12,000 returns **7,295,372**.

Each language exports `int64_t problem73(int64_t max_denominator)`.

## Workload

[`workload.json`](workload.json) covers the source examples, the default limit, and invalid bounds. The default uses one sample without warmup because it evaluates the full bounded denominator scan.

## TheAlgorithms reference

Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_073/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem73.c](../../../c/p/problem73.c) |
| C3 | [c3/p/problem73.c3](../../../c3/p/problem73.c3) |
| C++ | [cpp/p/problem73.cpp](../../../cpp/p/problem73.cpp) |
| Elisa | [elisa/p/problem73.elisa](../../../elisa/p/problem73.elisa) |
| Nim | [nim/p/problem73.nim](../../../nim/p/problem73.nim) |
| Odin | [odin/p/problem73.odin](../../../odin/p/problem73.odin) |
| Rust | [rust/p/problem73.rs](../../../rust/p/problem73.rs) |
| V | [v/p/problem73.v](../../../v/p/problem73.v) |
| Zig | [zig/p/problem73.zig](../../../zig/p/problem73.zig) |
