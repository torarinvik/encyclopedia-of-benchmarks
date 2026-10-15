# Binary power

Benchmark the pinned Java `BinaryPow.binPow` implementation, which computes integer powers by exponentiation by squaring with Java `int` arithmetic.

## Contract

- The `binary_scalar` ABI accepts two signed 64-bit values, interpreted as Java `int` inputs `base` and `exponent`.
- Inputs outside the signed 32-bit range return `-2147483649`.
- For in-range inputs, the result is the signed 32-bit interpretation of `base^exponent` modulo `2^32`. A nonpositive exponent returns `1`, matching the method body (including its behavior outside the JavaDoc precondition).
- Ports preserve the repeated-squaring recurrence and Java's defined 32-bit wraparound without relying on signed-overflow behavior.

## Source semantics

The pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/BinaryPow.java) initializes the result to 1, multiplies it by the base for set exponent bits, squares the base, and shifts the positive exponent right. Java `int` multiplication wraps modulo `2^32`; the benchmark returns that bit pattern as a signed 32-bit value widened to the ABI's 64-bit result.

## Workload

[`workload.json`](workload.json) covers zero and negative exponents, negative bases, set-bit multiplication, signed wraparound, large exponents, and inputs outside Java's `int` domain.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binary_pow.c`](../../../c/b/binary_pow.c) |
| C3 | [`c3/b/binary_pow.c3`](../../../c3/b/binary_pow.c3) |
| C++ | [`cpp/b/binary_pow.cpp`](../../../cpp/b/binary_pow.cpp) |
| Elisa | [`elisa/b/binary_pow.elisa`](../../../elisa/b/binary_pow.elisa) |
| Nim | [`nim/b/binary_pow.nim`](../../../nim/b/binary_pow.nim) |
| Odin | [`odin/b/binary_pow.odin`](../../../odin/b/binary_pow.odin) |
| Rust | [`rust/b/binary_pow.rs`](../../../rust/b/binary_pow.rs) |
| V | [`v/b/binary_pow.v`](../../../v/b/binary_pow.v) |
| Zig | [`zig/b/binary_pow.zig`](../../../zig/b/binary_pow.zig) |

