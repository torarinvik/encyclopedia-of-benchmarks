# Project Euler Problem 21: Amicable numbers

## Contract

For an exclusive limit `limit` in `1..=10000`, sum every `a` where `1 <= a < limit`, `d(a) != a`, and `d(d(a)) == a`, with `d(x)` the sum of positive proper divisors of `x`. A value is counted when it is below the limit even if its partner is above the limit. Invalid limits return `-1`.

The ports compute proper-divisor sums by checking divisor pairs through the square root, then test each value below the limit. This uses O(1) extra space and bounded divisor scans over the 10,000-value domain.

## Workload

[`workload.json`](workload.json) covers small limits, the 220/284 boundary (including the case where only 220 is below the limit), later amicable pairs, the canonical answer 31,626, and invalid limits.

## TheAlgorithms references

- Python [`solution`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_021/sol1.py) returns the sum of amicable numbers below an exclusive limit and gives 31,626 for 10,000.
- Ruby [`find_amicable_numbers`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/project_euler/problem_021/sol1.rb) computes the same result for a fixed exclusive limit of 10,000.
- The C [`sol1.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/project_euler/problem_21/sol1.c) is not treated as an equivalent implementation: its helper starts with `1 + N` (the full divisor sum rather than the proper-divisor sum), omits square-root divisors of perfect squares, and its search skips a candidate whenever its partner is at or above the limit.

This sum contract differs from [`amicable_pairs_below`](../../a/amicable_pairs_below/README.md), which enumerates pairs only when both members are below the limit.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem21.c](../../../c/p/problem21.c) |
| C3 | [c3/p/problem21.c3](../../../c3/p/problem21.c3) |
| C++ | [cpp/p/problem21.cpp](../../../cpp/p/problem21.cpp) |
| Elisa | [elisa/p/problem21.elisa](../../../elisa/p/problem21.elisa) |
| Nim | [nim/p/problem21.nim](../../../nim/p/problem21.nim) |
| Odin | [odin/p/problem21.odin](../../../odin/p/problem21.odin) |
| Rust | [rust/p/problem21.rs](../../../rust/p/problem21.rs) |
| V | [v/p/problem21.v](../../../v/p/problem21.v) |
| Zig | [zig/p/problem21.zig](../../../zig/p/problem21.zig) |
