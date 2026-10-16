# Project Euler Problem 38

## Contract

The pinned Python source has no input parameter. Its search returns the largest 1–9 pandigital concatenated product it finds by checking four-digit bases from 9999 down to 5000, then three-digit bases from 333 down to 100. The result is `932718654`.

The scalar benchmark ABI uses `0` as the no-argument placeholder and returns `-1` for any other input. Each language exports:

```c
int64_t problem38(int64_t unused);
```

The implementation checks that a candidate has exactly nine digits and contains each digit 1 through 9 once, then returns the first match in the source's descending search order.

## Workload

[`workload.json`](workload.json) covers the fixed no-argument result and rejected placeholder values. The runner and independent verifier both reproduce the bounded candidate search.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_038/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem38.c](../../../c/p/problem38.c) |
| C3 | [c3/p/problem38.c3](../../../c3/p/problem38.c3) |
| C++ | [cpp/p/problem38.cpp](../../../cpp/p/problem38.cpp) |
| Elisa | [elisa/p/problem38.elisa](../../../elisa/p/problem38.elisa) |
| Nim | [nim/p/problem38.nim](../../../nim/p/problem38.nim) |
| Odin | [odin/p/problem38.odin](../../../odin/p/problem38.odin) |
| Rust | [rust/p/problem38.rs](../../../rust/p/problem38.rs) |
| V | [v/p/problem38.v](../../../v/p/problem38.v) |
| Zig | [zig/p/problem38.zig](../../../zig/p/problem38.zig) |
