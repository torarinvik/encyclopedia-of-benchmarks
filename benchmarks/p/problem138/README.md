# Project Euler Problem 138: Special isosceles triangles

## Contract

`problem138(count)` sums the first `count` positive triangle lengths from the negative Pell recurrence after skipping its initial non-triangle solution. The workload supports counts 0 through 14; negative counts preserve the source’s empty-range result 0, and values above 14 return `-1`. The source’s default count 12 returns 1,118,049,290,473,932.

The pinned pair update is `m' = 9m + 20l`, `l' = 4m + 9l`, starting at `(m,l)=(2,1)`. Each update produces the next valid length `l'`, which is added to the sum. The ports use temporaries to preserve Python’s simultaneous assignment. Count 14 is the largest supported input whose recurrence values and sum fit signed 64-bit integers.

## Source review

The pinned Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_138/sol1.py) iterates `range(2, k + 2)`, which performs `k` updates and skips the initial `(m,l)=(2,1)` solution. It sums each updated `l`. The benchmark preserves the recurrence, update order, and number of terms; it bounds `k` to 14 to keep fixed-width intermediate values safe.

## Workload

[`workload.json`](workload.json) includes the source examples `k=2` and `k=5`, the canonical default `k=12`, the largest supported value, and empty/out-of-range cases.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem138.c](../../../c/p/problem138.c) |
| C3 | [c3/p/problem138.c3](../../../c3/p/problem138.c3) |
| C++ | [cpp/p/problem138.cpp](../../../cpp/p/problem138.cpp) |
| Elisa | [elisa/p/problem138.elisa](../../../elisa/p/problem138.elisa) |
| Nim | [nim/p/problem138.nim](../../../nim/p/problem138.nim) |
| Odin | [odin/p/problem138.odin](../../../odin/p/problem138.odin) |
| Rust | [rust/p/problem138.rs](../../../rust/p/problem138.rs) |
| V | [v/p/problem138.v](../../../v/p/problem138.v) |
| Zig | [zig/p/problem138.zig](../../../zig/p/problem138.zig) |
