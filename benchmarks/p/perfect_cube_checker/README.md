# Perfect cube checker

## Contract

Return `1` when the input is the cube of an integer and `0` otherwise. The supported input range is signed 32-bit; values outside it return `-1`. Negative inputs are checked by magnitude, and zero is a perfect cube. The exported C ABI entry point is `int64_t perfect_cube_checker(int64_t n);`.

The implementation searches integer roots from 0 through 1290. Cubing a candidate uses signed 64-bit arithmetic, which safely contains every cube in that range.

## Source review

The pinned C# `PerfectCubeChecker.IsPerfectCube` takes a signed 32-bit integer, negates negative inputs, rounds the floating cube root, then checks whether the rounded candidate cubed equals the magnitude. On this input domain its result matches the exact integer-root check. The file also contains an alternate binary-search method whose `int` cube multiplication can overflow; the benchmark follows the primary floating-root method's predicate and uses a progress-safe exact search. The primary method's negation of `int.MinValue` overflows in unchecked C#, but still returns false for that non-cube; the benchmark returns the same result for that input.

## Workload

[`workload.json`](workload.json) covers zero, signed perfect cubes, nearby non-cubes, the signed 32-bit boundaries, and inputs just outside the supported range.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/perfect_cube_checker.c`](../../../c/p/perfect_cube_checker.c) |
| C3 | [`c3/p/perfect_cube_checker.c3`](../../../c3/p/perfect_cube_checker.c3) |
| C++ | [`cpp/p/perfect_cube_checker.cpp`](../../../cpp/p/perfect_cube_checker.cpp) |
| Elisa | [`elisa/p/perfect_cube_checker.elisa`](../../../elisa/p/perfect_cube_checker.elisa) |
| Nim | [`nim/p/perfect_cube_checker.nim`](../../../nim/p/perfect_cube_checker.nim) |
| Odin | [`odin/p/perfect_cube_checker.odin`](../../../odin/p/perfect_cube_checker.odin) |
| Rust | [`rust/p/perfect_cube_checker.rs`](../../../rust/p/perfect_cube_checker.rs) |
| V | [`v/p/perfect_cube_checker.v`](../../../v/p/perfect_cube_checker.v) |
| Zig | [`zig/p/perfect_cube_checker.zig`](../../../zig/p/perfect_cube_checker.zig) |

## TheAlgorithms reference

- [C# `PerfectCubeChecker.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/PerfectCubeChecker.cs)
