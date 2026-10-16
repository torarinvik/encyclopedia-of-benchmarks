# Project Euler Problem 43

## Contract

The pinned Python source enumerates `permutations(range(n))` and applies the fixed substring divisibility tests for positions 2–10. Those indices are defined for the canonical `n=10` input. Each qualifying tuple is converted to an integer by joining its digits, so the port keeps the source's integer conversion semantics for a possible leading zero. The source-derived sum is `16,695,334,890` from six qualifying permutations; none happens to begin with zero. The scalar ABI accepts `10`; other values return `-1`.

Each language exports:

```c
int64_t problem43(int64_t n);
```

## Workload

[`workload.json`](workload.json) covers the canonical source input and rejected values. The runner checks against an exhaustive permutation model; the verifier uses an independent divisibility oracle.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_043/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem43.c](../../../c/p/problem43.c) |
| C3 | [c3/p/problem43.c3](../../../c3/p/problem43.c3) |
| C++ | [cpp/p/problem43.cpp](../../../cpp/p/problem43.cpp) |
| Elisa | [elisa/p/problem43.elisa](../../../elisa/p/problem43.elisa) |
| Nim | [nim/p/problem43.nim](../../../nim/p/problem43.nim) |
| Odin | [odin/p/problem43.odin](../../../odin/p/problem43.odin) |
| Rust | [rust/p/problem43.rs](../../../rust/p/problem43.rs) |
| V | [v/p/problem43.v](../../../v/p/problem43.v) |
| Zig | [zig/p/problem43.zig](../../../zig/p/problem43.zig) |
