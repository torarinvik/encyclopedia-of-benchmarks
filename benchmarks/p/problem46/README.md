# Project Euler Problem 46: Goldbach's Other Conjecture

## Contract

This benchmark wraps the pinned no-argument search with a scalar placeholder: input `0` runs the search, and every nonzero input returns `-1`. The search scans odd composites from `3` through `99,999` and returns the first value that cannot be written as `prime + 2 × square²`. It returns `-1` if the finite search bound contains no counterexample.

For each odd composite `n`, the ports try `i = 0, 1, ...` while `2i² <= n`, checking whether `n - 2i²` is prime. They stop at the first odd composite with no prime remainder.

## Workload

[`workload.json`](workload.json) covers the zero-only placeholder and nonzero invalid inputs. The pinned search returns `5,777`; the source's `compute_nums(2)` example gives the next counterexample as `5,993`.

## TheAlgorithms references

- Project Euler [Problem 46](https://projecteuler.net/problem=46) asks for the smallest odd composite not expressible as a prime plus twice a square.
- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_046/sol1.py) precomputes odd composites from 3 to 99,999, tests increasing square terms, and returns the first counterexample through `solution()`.

This is distinct from [`goldbach_conjecture`](../../g/goldbach_conjecture/README.md), which finds a prime-pair partition for an even input.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem46.c](../../../c/p/problem46.c) |
| C3 | [c3/p/problem46.c3](../../../c3/p/problem46.c3) |
| C++ | [cpp/p/problem46.cpp](../../../cpp/p/problem46.cpp) |
| Elisa | [elisa/p/problem46.elisa](../../../elisa/p/problem46.elisa) |
| Nim | [nim/p/problem46.nim](../../../nim/p/problem46.nim) |
| Odin | [odin/p/problem46.odin](../../../odin/p/problem46.odin) |
| Rust | [rust/p/problem46.rs](../../../rust/p/problem46.rs) |
| V | [v/p/problem46.v](../../../v/p/problem46.v) |
| Zig | [zig/p/problem46.zig](../../../zig/p/problem46.zig) |
