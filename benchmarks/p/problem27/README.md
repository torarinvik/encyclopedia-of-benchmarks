# Project Euler Problem 27: Quadratic primes

## Contract

For a coefficient limit in `1..=1000`, search `a = 1-limit, ..., limit-1` and `b = 2, ..., limit-1`. For each pair, count consecutive prime values of `n² + a*n + b` starting at `n=0`. Return `a*b` for the pair with the greatest count. If counts tie, retain the first pair in the source order: increasing `a`, then increasing `b`. Invalid limits return `-1`.

This scalar adapter uses the same limit for the source's two parameters (`solution(limit, limit)`). It preserves the source's exclusive bounds and strict-greater update. The bounded search uses O(limit²) coefficient pairs and trial division for primality. The canonical result at limit 1000 is `-59231`.

## Workload

[`workload.json`](workload.json) covers limits with no eligible `b`, the first coefficient case, the canonical limit, and invalid bounds. The canonical case uses one repetition per sample because it evaluates the full coefficient search.

## TheAlgorithms reference

- Python [`solution`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_027/sol1.py) searches `a` from `1-a_limit` through `a_limit-1`, prime `b` from 2 through `b_limit-1`, and updates only for a strictly longer run. The benchmark sets both source limits to the scalar input. Its default parameters produce `-59231`.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem27.c](../../../c/p/problem27.c) |
| C3 | [c3/p/problem27.c3](../../../c3/p/problem27.c3) |
| C++ | [cpp/p/problem27.cpp](../../../cpp/p/problem27.cpp) |
| Elisa | [elisa/p/problem27.elisa](../../../elisa/p/problem27.elisa) |
| Nim | [nim/p/problem27.nim](../../../nim/p/problem27.nim) |
| Odin | [odin/p/problem27.odin](../../../odin/p/problem27.odin) |
| Rust | [rust/p/problem27.rs](../../../rust/p/problem27.rs) |
| V | [v/p/problem27.v](../../../v/p/problem27.v) |
| Zig | [zig/p/problem27.zig](../../../zig/p/problem27.zig) |
