# Project Euler Problem 45: Triangular, pentagonal, and hexagonal numbers

## Contract

For a starting hexagonal index `start` in `0..=27,693`, return the first hexagonal number `H(n) = n * (2n - 1)` for `n >= start` that is also pentagonal. The search includes `start`. Inputs outside the bounded domain return `-1`. The source's default start is 144, which skips the already-known value 40,755 at index 143. Its canonical result is `H(27,693) = 1,533,776,805`.

The pinned Python source checks pentagonality with `(1 + sqrt(24*x + 1)) / 6 % 1 == 0`. The ports use the equivalent exact criterion: `24*x + 1` must be a perfect square and its square root plus one must be divisible by six. For this bound, the discriminant is below 2^53, so Python's float square root has enough precision for the same integer predicate. The bound is capped at the canonical match so the search stays finite for this benchmark.

## Workload

[`workload.json`](workload.json) covers start values 0 and 1, the known index 143, the default 144, searches that reach the canonical match from later indices, and invalid bounds.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_045/sol1.py) checks only hexagonal numbers because every hexagonal number is triangular, and returns the first pentagonal match at or after the supplied index.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem45.c](../../../c/p/problem45.c) |
| C3 | [c3/p/problem45.c3](../../../c3/p/problem45.c3) |
| C++ | [cpp/p/problem45.cpp](../../../cpp/p/problem45.cpp) |
| Elisa | [elisa/p/problem45.elisa](../../../elisa/p/problem45.elisa) |
| Nim | [nim/p/problem45.nim](../../../nim/p/problem45.nim) |
| Odin | [odin/p/problem45.odin](../../../odin/p/problem45.odin) |
| Rust | [rust/p/problem45.rs](../../../rust/p/problem45.rs) |
| V | [v/p/problem45.v](../../../v/p/problem45.v) |
| Zig | [zig/p/problem45.zig](../../../zig/p/problem45.zig) |
