# Project Euler Problem 52

## Contract

The pinned Python source has no input and checks positive integers in increasing order. It returns the first value whose products by 2, 3, 4, 5, and 6 have the same decimal digits. The benchmark ports preserve the ascending search and compare decimal digit counts; the first match is `142857`. The scalar ABI uses `0` as the no-argument placeholder and returns `-1` for other inputs.

Each language exports:

```c
int64_t problem52(int64_t unused);
```

## Workload

[`workload.json`](workload.json) checks the fixed source result and invalid placeholder values. The runner reproduces the bounded search through the first match; the verifier independently checks candidate digit multisets.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_052/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem52.c](../../../c/p/problem52.c) |
| C3 | [c3/p/problem52.c3](../../../c3/p/problem52.c3) |
| C++ | [cpp/p/problem52.cpp](../../../cpp/p/problem52.cpp) |
| Elisa | [elisa/p/problem52.elisa](../../../elisa/p/problem52.elisa) |
| Nim | [nim/p/problem52.nim](../../../nim/p/problem52.nim) |
| Odin | [odin/p/problem52.odin](../../../odin/p/problem52.odin) |
| Rust | [rust/p/problem52.rs](../../../rust/p/problem52.rs) |
| V | [v/p/problem52.v](../../../v/p/problem52.v) |
| Zig | [zig/p/problem52.zig](../../../zig/p/problem52.zig) |
