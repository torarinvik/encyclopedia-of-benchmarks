# Vampire number

This benchmark measures the pinned Java helper that checks whether two factors' digits are exactly the digits of their product.

## Contract

- Inputs are two unsigned 64-bit integers `a` and `b`, each in `1..=9999`.
- The source helper's `ignorePseudoVampireNumbers` argument is fixed to `true`. The result is `1` when `a` and `b` have the same number of decimal digits and the decimal digits of `a * b` match the combined digits of `a` and `b`, counting multiplicity; otherwise it is `0`.
- Inputs outside the range return `-1`.
- The bound keeps the product within the Java source's signed 32-bit multiplication range. The implementation uses digit counts instead of sorting or allocating strings.

The pinned source is a factor-pair predicate rather than a search over candidate numbers. Its helper does not check the conventional fang rule that both fangs cannot end in zero, or require the product to have twice as many digits as either factor. This benchmark preserves the helper's digit comparison and equal-factor-length option as written.

## Inspected upstream source

- [Java — `VampireNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/VampireNumber.java)

Build and record with the `binary_scalar` ABI family. Implementations are in `v/` in all nine language directories.
