# Project Euler Problem 56

## Contract

The pinned Python source returns the maximum decimal digit sum of `base**power` over `base in range(a)` and `power in range(b)`. The default call `solution()` uses `(100, 100)` and returns `972`; its examples also define `(10, 10) -> 45` and `(100, 200) -> 1872`. The package bounds both positive dimensions to `1..=200`, which contains these source examples and keeps work bounded. Inputs outside that domain return `-1`. The ports use base-10 digit arrays so powers larger than machine integers remain exact.

Each language exports:

```c
int64_t problem56(int64_t a, int64_t b);
```

## Workload

[`workload.json`](workload.json) covers the default result, documented examples, small boundaries, and invalid dimensions. The runner checks each case using Python's arbitrary-precision powers; the verifier checks them independently through decimal digit multiplication.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_056/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem56.c](../../../c/p/problem56.c) |
| C3 | [c3/p/problem56.c3](../../../c3/p/problem56.c3) |
| C++ | [cpp/p/problem56.cpp](../../../cpp/p/problem56.cpp) |
| Elisa | [elisa/p/problem56.elisa](../../../elisa/p/problem56.elisa) |
| Nim | [nim/p/problem56.nim](../../../nim/p/problem56.nim) |
| Odin | [odin/p/problem56.odin](../../../odin/p/problem56.odin) |
| Rust | [rust/p/problem56.rs](../../../rust/p/problem56.rs) |
| V | [v/p/problem56.v](../../../v/p/problem56.v) |
| Zig | [zig/p/problem56.zig](../../../zig/p/problem56.zig) |
