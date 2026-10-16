# Project Euler Problem 205: dice game

## Contract

The source has no input. The benchmark uses placeholder `0`; other values return `-1`. Peter rolls nine four-sided dice and Colin rolls six six-sided dice. Return the probability that Peter's total is strictly greater than Colin's, rounded to seven decimal places, as a fixed-point integer scaled by 10,000,000. The source result `0.5731441` is represented as **5,731,441**.

The ports build each total-frequency distribution by exact integer convolution. They count Peter wins against Colin totals strictly below Peter's total, exclude draws, divide by all `4^9 × 6^6` outcomes, and round the rational probability to seven decimal places using ties-to-even.

## Workload

[`workload.json`](workload.json) covers the source result and invalid placeholder values.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_205/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem205.c](../../../c/p/problem205.c) |
| C3 | [c3/p/problem205.c3](../../../c3/p/problem205.c3) |
| C++ | [cpp/p/problem205.cpp](../../../cpp/p/problem205.cpp) |
| Elisa | [elisa/p/problem205.elisa](../../../elisa/p/problem205.elisa) |
| Nim | [nim/p/problem205.nim](../../../nim/p/problem205.nim) |
| Odin | [odin/p/problem205.odin](../../../odin/p/problem205.odin) |
| Rust | [rust/p/problem205.rs](../../../rust/p/problem205.rs) |
| V | [v/p/problem205.v](../../../v/p/problem205.v) |
| Zig | [zig/p/problem205.zig](../../../zig/p/problem205.zig) |
