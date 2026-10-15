# Perfect square checker

## Contract

Return `1` when the input is a perfect square and `0` otherwise. Inputs are signed 32-bit integers; values outside that range return `-1`. Negative inputs return `0`. The exported C ABI entry point is `int64_t perfect_square_checker(int64_t n);`.

## Source review

The pinned C# method returns false for negative values. For nonnegative `int` inputs it converts `Math.Sqrt(number)` to `int`, which truncates to the floor, then checks whether the square of that integer equals the input. The benchmark uses an exact integer search over roots 0 through 46340, preserving that predicate on the signed 32-bit domain.

## Workload

[`workload.json`](workload.json) covers zero, small squares and their neighbors, the largest square that fits in int32, signed boundaries, and values just outside the supported range.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/perfect_square_checker.c`](../../../c/p/perfect_square_checker.c) |
| C3 | [`c3/p/perfect_square_checker.c3`](../../../c3/p/perfect_square_checker.c3) |
| C++ | [`cpp/p/perfect_square_checker.cpp`](../../../cpp/p/perfect_square_checker.cpp) |
| Elisa | [`elisa/p/perfect_square_checker.elisa`](../../../elisa/p/perfect_square_checker.elisa) |
| Nim | [`nim/p/perfect_square_checker.nim`](../../../nim/p/perfect_square_checker.nim) |
| Odin | [`odin/p/perfect_square_checker.odin`](../../../odin/p/perfect_square_checker.odin) |
| Rust | [`rust/p/perfect_square_checker.rs`](../../../rust/p/perfect_square_checker.rs) |
| V | [`v/p/perfect_square_checker.v`](../../../v/p/perfect_square_checker.v) |
| Zig | [`zig/p/perfect_square_checker.zig`](../../../zig/p/perfect_square_checker.zig) |

## TheAlgorithms reference

- [C# `PerfectSquareChecker.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/PerfectSquareChecker.cs)
