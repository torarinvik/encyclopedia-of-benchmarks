# Project Euler Problem 44: Pentagon numbers

## Contract

For an exclusive index limit from 1 through 5000, generate `P(n) = n(3n - 1)/2` for indices `1 <= n < limit`. Visit pairs in ascending lower index, then ascending upper index starting at the lower index, and return the first positive difference for which both the sum and difference are pentagonal. Return `-1` when the bounded search finds no pair or the limit is outside the supported range. At the source's default limit of 5000, the result is 5,482,660.

Pentagonal membership uses the identity that `x` is pentagonal iff `24x + 1` is a perfect square and its square root is congruent to `5 mod 6` (equivalently, `(root + 1) % 6 == 0`). The ports verify the square after taking its floating-point square-root estimate. With the 5000-index cap, all discriminants are below 1.8 billion and exactly representable as `f64`; the integer square check determines membership exactly. The nested search is O(limit²), so the canonical case is measured once without warmup.

## Source review

The pinned Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_044/sol1.py) constructs pentagonal values for indices `1..limit-1`, checks sums and differences in the same nested index order, and returns the first matching difference. It documents 5,482,660 for `limit=5000`. Its `is_pentagonal` function uses the same discriminant identity with floating-point square root and an integral formula check.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem44.c](../../../c/p/problem44.c) |
| C3 | [c3/p/problem44.c3](../../../c3/p/problem44.c3) |
| C++ | [cpp/p/problem44.cpp](../../../cpp/p/problem44.cpp) |
| Elisa | [elisa/p/problem44.elisa](../../../elisa/p/problem44.elisa) |
| Nim | [nim/p/problem44.nim](../../../nim/p/problem44.nim) |
| Odin | [odin/p/problem44.odin](../../../odin/p/problem44.odin) |
| Rust | [rust/p/problem44.rs](../../../rust/p/problem44.rs) |
| V | [v/p/problem44.v](../../../v/p/problem44.v) |
| Zig | [zig/p/problem44.zig](../../../zig/p/problem44.zig) |
