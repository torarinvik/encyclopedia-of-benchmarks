# Narcissistic number checker

## Contract

Return `1` when the input equals the sum of each decimal digit raised to the number of decimal digits, and `0` otherwise. Zero returns `1` because the source computes a digit count of zero, skips the digit loop, and compares the initial sum of zero with the input. Negative inputs return `0`. Inputs from `-2,147,483,648` through `999,999` are supported; other values return `-1`. The exported C ABI entry point is `int64_t narcissistic_number_checker(int64_t n);`.

The upper positive bound keeps the source's 32-bit sum arithmetic safe: six digits each contribute at most `9^6`, and six such terms fit in signed 32-bit range.

## Source review

The pinned C# method counts digits by repeatedly dividing a temporary copy by ten, then for positive inputs sums `Math.Pow(digit, digitCount)` and compares against the original input. Negative values are not processed by the digit-sum loop and return false. The benchmark uses integer repeated multiplication, which gives the same result over the supported positive range while avoiding floating point.

## Workload

[`workload.json`](workload.json) covers the zero behavior, negative inputs, source examples and known Narcissistic values, non-matches, the supported upper boundary, and values beyond the supported range.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/n/narcissistic_number_checker.c`](../../../c/n/narcissistic_number_checker.c) |
| C3 | [`c3/n/narcissistic_number_checker.c3`](../../../c3/n/narcissistic_number_checker.c3) |
| C++ | [`cpp/n/narcissistic_number_checker.cpp`](../../../cpp/n/narcissistic_number_checker.cpp) |
| Elisa | [`elisa/n/narcissistic_number_checker.elisa`](../../../elisa/n/narcissistic_number_checker.elisa) |
| Nim | [`nim/n/narcissistic_number_checker.nim`](../../../nim/n/narcissistic_number_checker.nim) |
| Odin | [`odin/n/narcissistic_number_checker.odin`](../../../odin/n/narcissistic_number_checker.odin) |
| Rust | [`rust/n/narcissistic_number_checker.rs`](../../../rust/n/narcissistic_number_checker.rs) |
| V | [`v/n/narcissistic_number_checker.v`](../../../v/n/narcissistic_number_checker.v) |
| Zig | [`zig/n/narcissistic_number_checker.zig`](../../../zig/n/narcissistic_number_checker.zig) |

## TheAlgorithms reference

- [C# `NarcissisticNumberChecker.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/NarcissisticNumberChecker.cs)
