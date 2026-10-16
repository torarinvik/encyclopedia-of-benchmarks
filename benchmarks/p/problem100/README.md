# Project Euler Problem 100

## Contract

Given a minimum total-disc threshold from 0 through 1,000,000,000,000, return the number of blue discs in the first arrangement whose total number of discs is strictly greater than the threshold. Invalid thresholds return `-1`.

The ports preserve the pinned source's integer recurrence and termination rule. Starting from `(previous_numerator, previous_denominator, numerator, denominator) = (1, 0, 1, 1)`, they continue while `numerator <= 2 * min_total - 1`, updating the numerator pair first and denominator pair second, then return `(denominator + 1) / 2`. The supported bound keeps all intermediate values in signed 64-bit arithmetic.

The source examples return **3** for threshold 2, **15** for 4, and **85** for 21. The canonical threshold 1,000,000,000,000 returns **756872327473**.

## Workload

[`workload.json`](workload.json) covers the source examples, zero threshold, the canonical threshold, and invalid limits.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_100/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem100.c](../../../c/p/problem100.c) |
| C3 | [c3/p/problem100.c3](../../../c3/p/problem100.c3) |
| C++ | [cpp/p/problem100.cpp](../../../cpp/p/problem100.cpp) |
| Elisa | [elisa/p/problem100.elisa](../../../elisa/p/problem100.elisa) |
| Nim | [nim/p/problem100.nim](../../../nim/p/problem100.nim) |
| Odin | [odin/p/problem100.odin](../../../odin/p/problem100.odin) |
| Rust | [rust/p/problem100.rs](../../../rust/p/problem100.rs) |
| V | [v/p/problem100.v](../../../v/p/problem100.v) |
| Zig | [zig/p/problem100.zig](../../../zig/p/problem100.zig) |
