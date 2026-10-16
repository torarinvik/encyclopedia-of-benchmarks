# Project Euler Problem 135: Same differences

## Contract

The pinned source counts solutions to `x² - y² - z² = n` by writing the consecutive arithmetic progression as `(a+d, a, a-d)`. This gives `n = a(4d-a)`. It scans each `first_term` from 1 through the input limit and every positive multiple `n` of that term through the same inclusive limit. It sets `4d = first_term + n/first_term`, requires divisibility by 4, then counts a solution only when `first_term > d` and `first_term < 4d`, which keeps all three terms positive. The output counts values `n` from 1 through the limit having exactly ten distinct solutions.

Although the problem statement asks for values less than one million, the pinned function increments its input and includes the original limit in both scans. The benchmark follows the executable function and supports limits through 1,000,000. Negative inputs return 0 from the source's empty ranges; values above 1,000,000 return -1 here. The source examples return 0 for 100, 45 for 10,000, and 292 for 50,050. The default returns 4,989.

Ports use integer division because `n` is enumerated only in multiples of `first_term`, so the quotient is exact. Per-value frequencies saturate at 11; this preserves whether a value has exactly ten solutions while bounding counters.

## Workload

The [workload JSON](workload.json) covers negative and zero limits, the least source example value with ten solutions, documented examples, the inclusive one-million default, and an out-of-domain limit.

## TheAlgorithms reference

- Python [sol1.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_135/sol1.py) factors each candidate through its first term and counts valid common differences.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem135.c](../../../c/p/problem135.c) |
| C3 | [c3/p/problem135.c3](../../../c3/p/problem135.c3) |
| C++ | [cpp/p/problem135.cpp](../../../cpp/p/problem135.cpp) |
| Elisa | [elisa/p/problem135.elisa](../../../elisa/p/problem135.elisa) |
| Nim | [nim/p/problem135.nim](../../../nim/p/problem135.nim) |
| Odin | [odin/p/problem135.odin](../../../odin/p/problem135.odin) |
| Rust | [rust/p/problem135.rs](../../../rust/p/problem135.rs) |
| V | [v/p/problem135.v](../../../v/p/problem135.v) |
| Zig | [zig/p/problem135.zig](../../../zig/p/problem135.zig) |
