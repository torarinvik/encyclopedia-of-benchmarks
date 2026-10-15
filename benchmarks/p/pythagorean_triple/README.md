# Pythagorean triple

This benchmark checks whether three integers, in any input order, form a positive Pythagorean triple.

## Contract

- The `i64_array_scalar` input is exactly `[a, b, c]`.
- Values must be in `[-32,768, 32,767]`. This bound ensures `x*x + y*y` fits signed 32-bit arithmetic, matching the Java source without overflow.
- If any value is nonpositive, return `0`, matching the source. Otherwise sort the three values and return `1` exactly when the two smaller squares sum to the largest square.
- Wrong-length arrays and values outside the stated range map to `-1` in the shared ABI. These invalid mappings are benchmark bounds; Java returns false for nonpositive values and does not check the upper bound.

The source sorts its three parameters, so side order does not affect the result. The symmetric signed bound preserves its `int` arithmetic for every positive triple in the benchmark domain. Source: [Java `PythagoreanTriple`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PythagoreanTriple.java).

Build and record with the `i64_array_scalar` ABI family and `benchmarks/run_i64_array_scalar.py`.
