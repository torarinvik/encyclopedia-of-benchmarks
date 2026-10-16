# Project Euler Problem 69

## Contract

For an inclusive limit from 1 through 1,000,000, return the number `n` in `1..=limit` that maximizes `n / φ(n)`. Invalid limits return `-1`.

The ports preserve the pinned source's totient-table sieve: initialize `φ(k)=k`, visit candidate divisors in ascending order, recognize primes where `φ(p)=p`, decrement `φ(p)`, then update multiples beginning at `2p`. The final scan also visits values in ascending order and replaces the current answer only when the ratio is strictly larger, so an equal ratio keeps the earliest value. The ports compare ratios by exact integer cross-products, which preserves that ordering and tie rule over the bounded domain.

The source examples are `10 -> 6`, `100 -> 30`, and `9973 -> 2310`; the default one-million limit returns **510,510**.

Each language exports `int64_t problem69(int64_t inclusive_limit)`.

## Workload

[`workload.json`](workload.json) covers the lower bound, source examples, the canonical default, and invalid limits. The one-million case uses one sample without warmup because it runs the complete totient sieve.

## TheAlgorithms reference

Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_069/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem69.c](../../../c/p/problem69.c) |
| C3 | [c3/p/problem69.c3](../../../c3/p/problem69.c3) |
| C++ | [cpp/p/problem69.cpp](../../../cpp/p/problem69.cpp) |
| Elisa | [elisa/p/problem69.elisa](../../../elisa/p/problem69.elisa) |
| Nim | [nim/p/problem69.nim](../../../nim/p/problem69.nim) |
| Odin | [odin/p/problem69.odin](../../../odin/p/problem69.odin) |
| Rust | [rust/p/problem69.rs](../../../rust/p/problem69.rs) |
| V | [v/p/problem69.v](../../../v/p/problem69.v) |
| Zig | [zig/p/problem69.zig](../../../zig/p/problem69.zig) |
