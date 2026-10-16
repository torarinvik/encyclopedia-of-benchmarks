# Project Euler Problem 95

## Contract

The pinned Python source computes proper-divisor sums for values through an inclusive `max_num`, then follows each start's chain while each next value is greater than 1 and at most the limit. A start counts only when following the chain returns to that same start. It scans starts in ascending order and replaces the winner only for a strictly longer chain, so ties keep the smallest start among equal-length cycles. Limits 1 through 1,000,000 are supported; other inputs return `-1`.

The ports compute proper-divisor sums with a divisor sieve and traverse chains in source order. A high bit temporarily marks each path value, then the path is restored before the next start. The canonical answer is `14316`; the documented 200,000 bound returns `12496`.

Each language exports `int64_t problem95(int64_t max_num)`.

## Workload

[`workload.json`](workload.json) covers small bounds, perfect numbers, the amicable pair, the documented long chain, the canonical limit, and invalid bounds.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_095/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem95.c](../../../c/p/problem95.c) |
| C3 | [c3/p/problem95.c3](../../../c3/p/problem95.c3) |
| C++ | [cpp/p/problem95.cpp](../../../cpp/p/problem95.cpp) |
| Elisa | [elisa/p/problem95.elisa](../../../elisa/p/problem95.elisa) |
| Nim | [nim/p/problem95.nim](../../../nim/p/problem95.nim) |
| Odin | [odin/p/problem95.odin](../../../odin/p/problem95.odin) |
| Rust | [rust/p/problem95.rs](../../../rust/p/problem95.rs) |
| V | [v/p/problem95.v](../../../v/p/problem95.v) |
| Zig | [zig/p/problem95.zig](../../../zig/p/problem95.zig) |
