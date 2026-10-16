# Project Euler Problem 80

## Contract

The pinned Python source computes square roots for integers 2 through 99 with a `decimal.Context(prec=105)`. It sums the integer digit and the following 99 decimal digits for each irrational square root; perfect squares are excluded because their formatted decimal representation has no fractional digits. The benchmark exposes this fixed computation through a zero placeholder and returns `-1` for any nonzero value. The result is `40886`.

The ports extract digits with the exact digit-by-digit square-root algorithm using base-1e9 limbs. It produces the same first 100 digits without relying on floating-point rounding. The scalar interface is `int64_t problem80(int64_t placeholder)`.

## Workload

[`workload.json`](workload.json) contains the pinned result and invalid placeholder cases.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_080/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem80.c](../../../c/p/problem80.c) |
| C3 | [c3/p/problem80.c3](../../../c3/p/problem80.c3) |
| C++ | [cpp/p/problem80.cpp](../../../cpp/p/problem80.cpp) |
| Elisa | [elisa/p/problem80.elisa](../../../elisa/p/problem80.elisa) |
| Nim | [nim/p/problem80.nim](../../../nim/p/problem80.nim) |
| Odin | [odin/p/problem80.odin](../../../odin/p/problem80.odin) |
| Rust | [rust/p/problem80.rs](../../../rust/p/problem80.rs) |
| V | [v/p/problem80.v](../../../v/p/problem80.v) |
| Zig | [zig/p/problem80.zig](../../../zig/p/problem80.zig) |
