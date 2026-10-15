# Sum without arithmetic operators

Compute the Java `int` sum using recursive XOR and carry propagation. Each call computes `sum = a ^ b`, `carry = (a & b) << 1`, then recurses on `(sum, carry)` until carry is zero. The result follows Java's signed 32-bit two's-complement wraparound.

## Contract

- The `binary_scalar` ABI accepts two signed 64-bit values; each must be in the signed 32-bit range.
- A valid result is the Java `int` sum, sign-extended to signed 64-bit. Overflow wraps modulo 2^32.
- An operand outside signed 32-bit range returns `-2147483649`, which cannot collide with a valid result.
- Ports keep the recursive carry method and use unsigned 32-bit bit patterns to express Java's fixed-width arithmetic safely.

## Source and related benchmarks

This follows the pinned Java [`SumWithoutArithmeticOperators.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/SumWithoutArithmeticOperators.java). Its method returns `a` when `b == 0`; otherwise it recurses with XOR sum bits and the shifted AND carry. The source documentation calls the values unsigned, but the method signature uses Java `int`, so the observable domain is signed int32 with Java wraparound.

The recurrence also appears in `bitwise_addition_recursive`, whose benchmark restricts inputs to nonnegative values and returns the exact widened sum. `addition_without_arithmetic` rejects int32 overflow, and `sum_of_two_integers` returns the exact mathematical sum in int64. This package preserves the Java method's signed inputs and wrapped int32 output.

## Workload and ports

[`workload.json`](workload.json) covers the source examples, negative values, carry propagation, Java overflow wraparound, and invalid operands.

| Language | Source |
| --- | --- |
| C | [`c/s/sum_without_arithmetic_operators.c`](../../../c/s/sum_without_arithmetic_operators.c) |
| C3 | [`c3/s/sum_without_arithmetic_operators.c3`](../../../c3/s/sum_without_arithmetic_operators.c3) |
| C++ | [`cpp/s/sum_without_arithmetic_operators.cpp`](../../../cpp/s/sum_without_arithmetic_operators.cpp) |
| Elisa | [`elisa/s/sum_without_arithmetic_operators.elisa`](../../../elisa/s/sum_without_arithmetic_operators.elisa) |
| Nim | [`nim/s/sum_without_arithmetic_operators.nim`](../../../nim/s/sum_without_arithmetic_operators.nim) |
| Odin | [`odin/s/sum_without_arithmetic_operators.odin`](../../../odin/s/sum_without_arithmetic_operators.odin) |
| Rust | [`rust/s/sum_without_arithmetic_operators.rs`](../../../rust/s/sum_without_arithmetic_operators.rs) |
| V | [`v/s/sum_without_arithmetic_operators.v`](../../../v/s/sum_without_arithmetic_operators.v) |
| Zig | [`zig/s/sum_without_arithmetic_operators.zig`](../../../zig/s/sum_without_arithmetic_operators.zig) |

The workload uses the shared `binary_scalar` interface. A runner oracle entry for this candidate may be needed before the workload can be measured.
