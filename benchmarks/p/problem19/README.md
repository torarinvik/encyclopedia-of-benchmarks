# Project Euler Problem 19: Counting Sundays

## Contract

Count the months beginning on Sunday from January 1901 through December 2000, inclusive. Weekdays use Sunday = 0 through Saturday = 6. The ports start from the known weekday for 1 January 1901 (Tuesday), advance by each Gregorian month length, and apply the Gregorian leap-year rule. The result is 171.

The source operation has a fixed period and no arguments. A zero-valued placeholder is accepted to use the shared scalar runner ABI; any nonzero placeholder returns `-1`.

## Source review

- Go [`Problem19`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_19/problem19.go) matches the fixed 1901–2000 period and weekday convention.
- C [`sol1.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/project_euler/problem_19/sol1.c) counts the same fixed period. It skips advancing after December 2000, which avoids counting January 2001.
- Python [`solution`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_019/sol1.py) also computes the fixed twentieth-century count and documents 171.
- Julia [`problem_019`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/project_euler/problem_019.jl) is excluded. Its Zeller helper divides `13 * (m + 1)` by 4 rather than 5, shifting the weekday, and the counting loop advances before checking the month start and processes the December transition into the following January.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem19.c](../../../c/p/problem19.c) |
| C3 | [c3/p/problem19.c3](../../../c3/p/problem19.c3) |
| C++ | [cpp/p/problem19.cpp](../../../cpp/p/problem19.cpp) |
| Elisa | [elisa/p/problem19.elisa](../../../elisa/p/problem19.elisa) |
| Nim | [nim/p/problem19.nim](../../../nim/p/problem19.nim) |
| Odin | [odin/p/problem19.odin](../../../odin/p/problem19.odin) |
| Rust | [rust/p/problem19.rs](../../../rust/p/problem19.rs) |
| V | [v/p/problem19.v](../../../v/p/problem19.v) |
| Zig | [zig/p/problem19.zig](../../../zig/p/problem19.zig) |
