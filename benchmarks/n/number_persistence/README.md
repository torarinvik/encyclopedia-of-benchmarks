# Multiplicative persistence

This benchmark returns the number of repeated decimal digit-product steps needed to reduce a nonnegative integer to one digit.

## Contract

- The `scalar` input is an integer in `[0, 2,147,483,647]`, the complete nonnegative signed Java `int` range. The upper bound keeps the source's intermediate digit products within signed 32-bit range: a first product is at most `2 × 9^9 = 774,840,978`; later products are at most `9^9 = 387,420,489`.
- For each step while the current value is at least 10, multiply its decimal digits and replace the value with that product. Return the number of steps.
- Zero and all single-digit inputs return `0`. A digit product containing zero becomes zero and the loop then stops.
- Negative values and values above the supported bound map to `-1` in this benchmark. The pinned Java method throws on negative input; `-1` is the shared ABI invalid-input mapping.

The pinned Java class exposes both `multiplicativePersistence(int)` and `additivePersistence(int)`. This package benchmarks the multiplicative method; it does not combine or dispatch between the two. Its result is a step count, whereas the separate `digital_root` benchmark returns the final repeated digit sum. Source: [Java `NumberPersistence`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/NumberPersistence.java).

Build and record with the `scalar` ABI family and `benchmarks/run_scalar.py`.
