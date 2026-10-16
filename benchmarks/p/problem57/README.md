# Project Euler Problem 57

## Contract

The pinned Python source counts convergents of sqrt(2) for iterations `1..n`, where the next numerator and denominator are `p + 2q` and `p + q`. It defaults to `n=1000`; examples include `n=14 -> 2`, `n=100 -> 15`, and `n=10000 -> 1508`. The package supports `n <= 10000`; nonpositive limits produce zero as the source's empty range does, and values above the bound return `-1`. The ports use exact decimal digit arrays, avoiding fixed-width overflow while preserving the source's digit-length comparison. A 5,000-digit buffer is sufficient: the next numerator is `p + 2q <= 3p` because `p >= q`, so after 10,000 steps the numerator is below `3^10000`, which has 4,772 decimal digits.

Each language exports:

```c
int64_t problem57(int64_t n);
```

## Workload

[`workload.json`](workload.json) covers the default limit, documented examples, zero/negative limits, and the upper bound. The runner and verifier use exact integer recurrences.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_057/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem57.c](../../../c/p/problem57.c) |
| C3 | [c3/p/problem57.c3](../../../c3/p/problem57.c3) |
| C++ | [cpp/p/problem57.cpp](../../../cpp/p/problem57.cpp) |
| Elisa | [elisa/p/problem57.elisa](../../../elisa/p/problem57.elisa) |
| Nim | [nim/p/problem57.nim](../../../nim/p/problem57.nim) |
| Odin | [odin/p/problem57.odin](../../../odin/p/problem57.odin) |
| Rust | [rust/p/problem57.rs](../../../rust/p/problem57.rs) |
| V | [v/p/problem57.v](../../../v/p/problem57.v) |
| Zig | [zig/p/problem57.zig](../../../zig/p/problem57.zig) |
