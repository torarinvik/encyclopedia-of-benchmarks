# Project Euler Problem 10: Ruby cumulative-prime prefix

## Contract

`problem10_ruby_prefix(max_total)` preserves the pinned Ruby implementation's cumulative-prime prefix rule. The workload supports `max_total` from 0 through 2,000,000; values outside that benchmark domain return `-1`.

The source initializes both the running total and returned total to 1, visits candidate integers in ascending order starting at 2, and adds a candidate when it is prime. It updates the returned total only when the new cumulative total is strictly less than `max_total`. The scan also requires the candidate itself to be strictly below `max_total`. Therefore the result is not the sum of every prime below the bound: for example, a bound of 10 returns 6, a bound of 11 returns 6 because the next total equals the bound, and a bound of 12 returns 11. Bounds 0 through 3 return the source's initial value 1.

The prime predicate follows the source's 2/3 checks and 6k±1 trial divisors. At the default bound of 2,000,000, the result is 1,999,237.

## Workload

[`workload.json`](workload.json) includes the source seed, strict-equality boundaries, small examples, canonical default, and invalid bounds.

## TheAlgorithms reference

- Ruby [`sol1.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/project_euler/problem_010/sol1.rb)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem10_ruby_prefix.c](../../../c/p/problem10_ruby_prefix.c) |
| C3 | [c3/p/problem10_ruby_prefix.c3](../../../c3/p/problem10_ruby_prefix.c3) |
| C++ | [cpp/p/problem10_ruby_prefix.cpp](../../../cpp/p/problem10_ruby_prefix.cpp) |
| Elisa | [elisa/p/problem10_ruby_prefix.elisa](../../../elisa/p/problem10_ruby_prefix.elisa) |
| Nim | [nim/p/problem10_ruby_prefix.nim](../../../nim/p/problem10_ruby_prefix.nim) |
| Odin | [odin/p/problem10_ruby_prefix.odin](../../../odin/p/problem10_ruby_prefix.odin) |
| Rust | [rust/p/problem10_ruby_prefix.rs](../../../rust/p/problem10_ruby_prefix.rs) |
| V | [v/p/problem10_ruby_prefix.v](../../../v/p/problem10_ruby_prefix.v) |
| Zig | [zig/p/problem10_ruby_prefix.zig](../../../zig/p/problem10_ruby_prefix.zig) |
