# Project Euler Problem 58: Spiral primes

## Contract

For a ratio threshold from 0.1 through 0.6, return the first odd side length greater than 1 for which the fraction of prime numbers on both diagonals is strictly below the threshold. Invalid thresholds return `-1.0`. The result is an exactly representable binary64 integer.

The spiral begins at side 3 with 3 primes among 5 diagonal entries. Each new layer adds the three non-square corners `side² + k(side + 1)` for `k = 1, 2, 3`; the fourth corner is the next square and is composite. After checking those corners, the ports add 4 to the diagonal count by advancing the side by 2. Primality uses trial division by 6k±1 through the square root.

The threshold floor of 0.1 keeps the search bounded to the canonical side length 26,241. The source tests `prime_count / (2 * side - 1) >= ratio` before adding a layer, then returns the next side after the ratio becomes strictly lower. The workload uses the float64 unary ABI because the source accepts a binary64 ratio; returned side lengths are integer-valued doubles.

## Source review

The pinned Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_058/sol1.py) starts with side 3 and prime count 3, checks the three non-square corners of each next layer, and stops when the current ratio is below the requested threshold. It documents `0.5 → 11`, `0.2 → 309`, `0.111 → 11317`, and uses `0.1` by default.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem58.c](../../../c/p/problem58.c) |
| C3 | [c3/p/problem58.c3](../../../c3/p/problem58.c3) |
| C++ | [cpp/p/problem58.cpp](../../../cpp/p/problem58.cpp) |
| Elisa | [elisa/p/problem58.elisa](../../../elisa/p/problem58.elisa) |
| Nim | [nim/p/problem58.nim](../../../nim/p/problem58.nim) |
| Odin | [odin/p/problem58.odin](../../../odin/p/problem58.odin) |
| Rust | [rust/p/problem58.rs](../../../rust/p/problem58.rs) |
| V | [v/p/problem58.v](../../../v/p/problem58.v) |
| Zig | [zig/p/problem58.zig](../../../zig/p/problem58.zig) |
