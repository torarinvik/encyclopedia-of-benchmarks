# Project Euler Problem 191: Prize strings

## Contract

`problem191(days)` counts attendance strings of the requested length according to the pinned implementation. The workload supports 0 through 65 days; values outside that range return `-1`. The 30-day source result is 1,918,080,160.

The source recurrence tracks `(days_remaining, absent, late)`: `absent == 2` is invalid, `late == 3` is invalid, an `A` increments `absent` and resets `late`, an `L` increments `late`, and an `O` resets `late`. In the pinned code, `absent` is not reset by `L` or `O`, so it counts total A entries rather than consecutive A entries. The ports preserve this executable state transition. This differs from the prose attendance rule’s symbol assignment, but the package follows the pinned algorithm’s recursion.

The table implementation evaluates the same memoized recursion from zero remaining days upward. For every valid `(absent, late)` state, the empty suffix contributes one. Each larger remaining-day state sums late, absent, and on-time transitions, with invalid states contributing zero. The maximum of 65 keeps the result within signed 64-bit range.

## Source review

The pinned Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_191/sol1.py) memoizes `_calculate(days, absent, late)`, returning zero at `absent == 2` or `late == 3`, one at `days == 0`, and otherwise summing the three attendance transitions. `solution(days)` starts at `(0,0)`. Negative days do not terminate in the source recursion; the benchmark bounds them to `-1`.

## Workload

[`workload.json`](workload.json) covers short periods, the four-day source example, the canonical 30 days, the largest signed-64-bit-safe period (65 days), and invalid bounds.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem191.c](../../../c/p/problem191.c) |
| C3 | [c3/p/problem191.c3](../../../c3/p/problem191.c3) |
| C++ | [cpp/p/problem191.cpp](../../../cpp/p/problem191.cpp) |
| Elisa | [elisa/p/problem191.elisa](../../../elisa/p/problem191.elisa) |
| Nim | [nim/p/problem191.nim](../../../nim/p/problem191.nim) |
| Odin | [odin/p/problem191.odin](../../../odin/p/problem191.odin) |
| Rust | [rust/p/problem191.rs](../../../rust/p/problem191.rs) |
| V | [v/p/problem191.v](../../../v/p/problem191.v) |
| Zig | [zig/p/problem191.zig](../../../zig/p/problem191.zig) |
