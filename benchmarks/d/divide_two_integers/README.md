# Divide Two Integers

This benchmark divides signed 32-bit integers without using a native division operator in the algorithm. It follows the doubled-divisor strategy in C LeetCode 29, with widened arithmetic so the minimum signed input is safe on every target.

## Contract

- Input is `[dividend, divisor]`, exactly two signed 32-bit integers.
- A zero divisor or malformed input returns the signed 64-bit sentinel `-2147483649`.
- The result truncates toward zero and saturates to the signed 32-bit range. In particular, `-2147483648 / -1` returns `2147483647`.
- Each implementation compares and subtracts power-of-two multiples of the divisor. It uses only portable integer operations and no processor-specific instructions.

The numeric C LeetCode source stem `29` is cataloged under the alphabetic benchmark name `divide_two_integers`. Its original signed `int` operations need careful widening around `INT32_MIN`; these ports use signed 64-bit magnitudes and make the saturation behavior explicit.

Run `python3 benchmarks/verify_divide_two_integers.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to check the ports against a truncation-toward-zero oracle, dense small-input pairs, seeded random values, signed boundaries, invalid divisors, and the workload.

## Implementations

The portable ports are [`c/d/divide_two_integers.c`](../../../c/d/divide_two_integers.c), [`c3/d/divide_two_integers.c3`](../../../c3/d/divide_two_integers.c3), [`cpp/d/divide_two_integers.cpp`](../../../cpp/d/divide_two_integers.cpp), [`elisa/d/divide_two_integers.elisa`](../../../elisa/d/divide_two_integers.elisa), [`nim/d/divide_two_integers.nim`](../../../nim/d/divide_two_integers.nim), [`odin/d/divide_two_integers.odin`](../../../odin/d/divide_two_integers.odin), [`rust/d/divide_two_integers.rs`](../../../rust/d/divide_two_integers.rs), [`v/d/divide_two_integers.v`](../../../v/d/divide_two_integers.v), and [`zig/d/divide_two_integers.zig`](../../../zig/d/divide_two_integers.zig).

## Upstream reference

- [C LeetCode 29](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/29.c)
