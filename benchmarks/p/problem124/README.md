# Project Euler Problem 124: Ordered radicals

## Contract

`problem124(n_max, k)` returns the one-based kth integer from `1..n_max`, ordered by `rad(n)` and then by the integer itself. Here `rad(n)` is the product of the distinct prime factors of `n`, with `rad(1)=1`. The workload supports `1 <= n_max <= 100,000` and `1 <= k <= n_max`; invalid pairs return `-1`. The canonical input `(100000, 10000)` returns 21,417.

The ports use a prime sieve to compute each radical, count values per radical, then scan radical buckets and values in ascending order. This produces the same ordering as sorting by `(rad(n), n)` and preserves the source’s tie order.

## Source review

The pinned Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_124/sol1.py) generates primes through `n_max`, enumerates each square-free product of distinct primes as a radical, then generates all numbers with that exact set of prime factors. It visits radical keys in sorted order, sorts values within each radical, and returns the one-based rank. It special-cases `k == 1` as 1. The benchmark uses the equivalent key ordering `(rad(n), n)`; this gives 1 for the first item and preserves all subsequent radical and tie ordering. The supported bound fits signed 64-bit arithmetic.

## Workload

[`workload.json`](workload.json) covers the source examples `(10,6)` and `(10,9)`, the canonical case, boundary ranks, and invalid input pairs.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem124.c](../../../c/p/problem124.c) |
| C3 | [c3/p/problem124.c3](../../../c3/p/problem124.c3) |
| C++ | [cpp/p/problem124.cpp](../../../cpp/p/problem124.cpp) |
| Elisa | [elisa/p/problem124.elisa](../../../elisa/p/problem124.elisa) |
| Nim | [nim/p/problem124.nim](../../../nim/p/problem124.nim) |
| Odin | [odin/p/problem124.odin](../../../odin/p/problem124.odin) |
| Rust | [rust/p/problem124.rs](../../../rust/p/problem124.rs) |
| V | [v/p/problem124.v](../../../v/p/problem124.v) |
| Zig | [zig/p/problem124.zig](../../../zig/p/problem124.zig) |
