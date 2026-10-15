# Krishnamurthy number checker

## Contract

Return `1` when a positive signed 32-bit input equals the sum of the factorials of its decimal digits, and `0` otherwise. Zero and negative inputs return `0`, matching the source guard. Inputs outside signed 32-bit range return `-1`. The exported C ABI entry point is `int64_t krishnamurthy_number_checker(int64_t n);`.

Each digit factorial is at most `9! = 362880`, so the sum for any signed 32-bit input fits comfortably in signed 64-bit arithmetic.

## Source review

The pinned C# `KrishnamurthyNumberChecker.IsKMurthyNumber` returns false for `n <= 0`, then sums `Factorial.Calculate(n % 10)` while consuming decimal digits and compares that sum with the original value. The port uses the same digit-factorial predicate; the local factorial table/formula is equivalent for digits 0 through 9.

## Workload

[`workload.json`](workload.json) covers zero, negative inputs, the one-digit values 1 and 2, the source example 145, another known value 40585, non-matches, int32 limits, and out-of-range inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/k/krishnamurthy_number_checker.c`](../../../c/k/krishnamurthy_number_checker.c) |
| C3 | [`c3/k/krishnamurthy_number_checker.c3`](../../../c3/k/krishnamurthy_number_checker.c3) |
| C++ | [`cpp/k/krishnamurthy_number_checker.cpp`](../../../cpp/k/krishnamurthy_number_checker.cpp) |
| Elisa | [`elisa/k/krishnamurthy_number_checker.elisa`](../../../elisa/k/krishnamurthy_number_checker.elisa) |
| Nim | [`nim/k/krishnamurthy_number_checker.nim`](../../../nim/k/krishnamurthy_number_checker.nim) |
| Odin | [`odin/k/krishnamurthy_number_checker.odin`](../../../odin/k/krishnamurthy_number_checker.odin) |
| Rust | [`rust/k/krishnamurthy_number_checker.rs`](../../../rust/k/krishnamurthy_number_checker.rs) |
| V | [`v/k/krishnamurthy_number_checker.v`](../../../v/k/krishnamurthy_number_checker.v) |
| Zig | [`zig/k/krishnamurthy_number_checker.zig`](../../../zig/k/krishnamurthy_number_checker.zig) |

## TheAlgorithms reference

- [C# `KrishnamurthyNumberChecker.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/KrishnamurthyNumberChecker.cs)
