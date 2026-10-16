# Project Euler Problem 12

## Contract

Given `minimum_divisors` in `0..=500`, return the first triangular number with at least that many positive divisors. Inputs outside the range return `-1`.

The ports split `n(n+1)/2` into two coprime factors before counting divisors by prime factorization. They use O(k√k) time through the searched index `k` and O(1) extra space. The pinned Go source also searches triangular numbers, but its factor-pair counter adds two for every factor through the square root and therefore counts square roots twice for perfect squares. The ports use exact divisor counts. The canonical threshold 500 returns 76,576,500.

## Workload

[`workload.json`](workload.json) covers zero and small divisor thresholds, the example with more than five divisors, the canonical 500-divisor threshold, and invalid bounds. Measurement uses one repetition per sample because the canonical search factors many candidates.

## TheAlgorithms reference

- Go [`Problem12`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_12/problem12.go) accumulates triangular numbers and tests their divisor counts against a caller-provided threshold.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem12.c](../../../c/p/problem12.c) |
| C3 | [c3/p/problem12.c3](../../../c3/p/problem12.c3) |
| C++ | [cpp/p/problem12.cpp](../../../cpp/p/problem12.cpp) |
| Elisa | [elisa/p/problem12.elisa](../../../elisa/p/problem12.elisa) |
| Nim | [nim/p/problem12.nim](../../../nim/p/problem12.nim) |
| Odin | [odin/p/problem12.odin](../../../odin/p/problem12.odin) |
| Rust | [rust/p/problem12.rs](../../../rust/p/problem12.rs) |
| V | [v/p/problem12.v](../../../v/p/problem12.v) |
| Zig | [zig/p/problem12.zig](../../../zig/p/problem12.zig) |
