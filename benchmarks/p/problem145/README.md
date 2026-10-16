# Project Euler Problem 145: Reversible numbers

## Contract

`problem145(max_power)` counts reversible positive integers below `10^max_power`. A number is reversible when adding it to its decimal reversal produces only odd digits, with no leading zero allowed in either number. The workload supports powers 0 through 9; negative values preserve the source’s empty-range result 0, and values above 9 return `-1`. The canonical result for `max_power=9` is 608,720.

The ports follow the source’s carry-based digit recursion. They assign symmetric digit pairs, choose the opposite parity needed to make each output digit odd, propagate the carry inward, reject zero outer digits, and apply the source skip for lengths congruent to 1 modulo 4.

## Source review

The pinned Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_145/sol1.py) sums the recursive count for each length from 1 through `max_power`. Its optimized helper returns zero immediately for lengths 1, 5, and 9, then delegates to the carry recursion. The benchmark preserves those length and digit-parity rules and bounds the maximum to 9, the source’s canonical default.

## Workload

[`workload.json`](workload.json) includes the source examples for powers 3, 6, and 7, the canonical power 9, and empty/out-of-range cases.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem145.c](../../../c/p/problem145.c) |
| C3 | [c3/p/problem145.c3](../../../c3/p/problem145.c3) |
| C++ | [cpp/p/problem145.cpp](../../../cpp/p/problem145.cpp) |
| Elisa | [elisa/p/problem145.elisa](../../../elisa/p/problem145.elisa) |
| Nim | [nim/p/problem145.nim](../../../nim/p/problem145.nim) |
| Odin | [odin/p/problem145.odin](../../../odin/p/problem145.odin) |
| Rust | [rust/p/problem145.rs](../../../rust/p/problem145.rs) |
| V | [v/p/problem145.v](../../../v/p/problem145.v) |
| Zig | [zig/p/problem145.zig](../../../zig/p/problem145.zig) |
