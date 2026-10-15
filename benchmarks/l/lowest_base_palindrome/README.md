# Lowest base palindrome

This benchmark returns the smallest integer base at least 2 in which a nonnegative integer's representation reads the same forward and backward.

## Contract

- The scalar input is in `[0, 64]`. The bound keeps the source's increasing-base search small while preserving its result on every supported input.
- The search starts at base 2 and continues upward until the representation is palindromic. For values 0 and 1, the pinned method special-cases the value as palindromic and returns base 2 before converting any digits. For value 2, base 2 gives `10`, so the result is base 3. For values at least 3, base `n - 1` represents `n` as `11`, so the search is guaranteed to finish no later than that base.
- Negative inputs and values above 64 map to `-1` in the benchmark ABI. The source throws for negative inputs; the upper bound is a benchmark limit.

The pinned Java method tests bases in ascending order. The portable implementations reverse the base digits arithmetically, which yields the same palindrome decision for the bounded nonnegative domain. This operation finds a number's lowest palindromic base; it is distinct from checking palindromicity in one fixed base. Source: [Java `LowestBasePalindrome`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/LowestBasePalindrome.java).

Build and record with the `scalar` ABI family and `benchmarks/run_scalar.py`.
