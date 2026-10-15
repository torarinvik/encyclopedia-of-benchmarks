# Modulo by a power of two

This benchmark follows the pinned Java bit-mask routine. The `i64_array_scalar` input is a two-value array `[x, n]`, where the result is `x & ((1 << n) - 1)` using Java's signed 32-bit shift and mask behavior.

## Contract

- `x` must be in the signed 32-bit range `[-2,147,483,648, 2,147,483,647]`.
- `n` must be in `[1, 31]`. The Java source throws for `n <= 0`; at `n >= 32`, Java masks the shift count modulo 32, so those values are outside this benchmark contract.
- The result is the low `n` bits of `x`. For nonnegative `x`, this equals the remainder modulo `2^n`. For negative `x`, the source's bitwise result is nonnegative and is not Java's signed `%` remainder.
- Missing, extra, or out-of-range packed values map to `-1` in the shared ABI. The pinned Java method itself only throws for a nonpositive exponent; the other invalid mappings belong to the benchmark contract.

The maximum exponent, 31, is safe to reproduce with a wider signed intermediate: Java evaluates `(1 << 31) - 1` with 32-bit wraparound to `0x7fffffff`, and this mask selects the low 31 bits. Source: [Java `ModuloPowerOfTwo`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/ModuloPowerOfTwo.java).

Build and record with the `i64_array_scalar` ABI family and `benchmarks/run_i64_array_scalar.py`.
