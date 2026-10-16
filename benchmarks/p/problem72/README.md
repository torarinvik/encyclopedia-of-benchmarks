# Project Euler Problem 72

## Contract

The pinned Python `sol1.py` initializes Euler totients and applies a sieve, then returns the sum of `phi(d)` for every denominator from 2 through the inclusive `limit`. The benchmark accepts limits from 0 through 1,000,000; limits 0 and 1 return zero, while out-of-range inputs return `-1`. The canonical result for 1,000,000 is `303963552391`.

The ports use an in-place totient sieve. Their scalar interface is:

```c
int64_t problem72(int64_t limit);
```

## Workload

[`workload.json`](workload.json) covers the empty and smallest sums, the Project Euler example at 8, several documented reference values, the canonical million limit, and invalid bounds.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_072/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem72.c](../../../c/p/problem72.c) |
| C3 | [c3/p/problem72.c3](../../../c3/p/problem72.c3) |
| C++ | [cpp/p/problem72.cpp](../../../cpp/p/problem72.cpp) |
| Elisa | [elisa/p/problem72.elisa](../../../elisa/p/problem72.elisa) |
| Nim | [nim/p/problem72.nim](../../../nim/p/problem72.nim) |
| Odin | [odin/p/problem72.odin](../../../odin/p/problem72.odin) |
| Rust | [rust/p/problem72.rs](../../../rust/p/problem72.rs) |
| V | [v/p/problem72.v](../../../v/p/problem72.v) |
| Zig | [zig/p/problem72.zig](../../../zig/p/problem72.zig) |
