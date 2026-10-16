# Project Euler Problem 25: 1000-digit Fibonacci number

## Contract

For a requested digit count from 2 through 1000, return the 1-based index of the first Fibonacci term with at least that many decimal digits. The sequence uses `F1 = 1`, `F2 = 1`; because its digit count increases by one at a time, “at least” is equivalent to the first term with exactly that many digits. Inputs outside 2..=1000 return `-1`.

The ports keep two Fibonacci values as little-endian base-10 digit arrays, add one digit at a time with carry, and stop when the active digit count reaches the requested threshold. The fixed arrays hold at most 1000 digits. The output index is at most 4782 and fits in signed 64-bit integer.

The 1-digit case is intentionally outside the common source overlap: the Python solutions and Ruby implementation use different starting/index conventions there. The package standardizes on the shared 2..=1000 domain.

## Source review

- Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_025/sol1.py), [`sol2`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_025/sol2.py), and [`sol3`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_025/sol3.py), and Ruby [`sol1`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/project_euler/problem_025/sol1.rb) agree on inputs 2..1000. Python `sol1` recomputes each Fibonacci value from the beginning, so the canonical case is intentionally run once per sample with no warmup.
- C [`sol1.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/project_euler/problem_25/sol1.c) hardcodes `MAX_DIGITS = 1000` and is a console program, so it is treated as fixed-input only and overlaps at the canonical 1000-digit case.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem25.c](../../../c/p/problem25.c) |
| C3 | [c3/p/problem25.c3](../../../c3/p/problem25.c3) |
| C++ | [cpp/p/problem25.cpp](../../../cpp/p/problem25.cpp) |
| Elisa | [elisa/p/problem25.elisa](../../../elisa/p/problem25.elisa) |
| Nim | [nim/p/problem25.nim](../../../nim/p/problem25.nim) |
| Odin | [odin/p/problem25.odin](../../../odin/p/problem25.odin) |
| Rust | [rust/p/problem25.rs](../../../rust/p/problem25.rs) |
| V | [v/p/problem25.v](../../../v/p/problem25.v) |
| Zig | [zig/p/problem25.zig](../../../zig/p/problem25.zig) |
