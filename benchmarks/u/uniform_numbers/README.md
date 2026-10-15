# Uniform numbers

This benchmark counts positive integers whose decimal digits are all equal, from 1 through the input limit.

## Contract

- The input is a signed 64-bit integer from `0` through `999,999,999`.
- Return the number of positive uniform integers less than or equal to the input. For example, the uniform numbers up to 1234 are the nine one-digit values, nine two-digit values, nine three-digit values, and 1111, for a result of 28.
- Inputs outside the range return `-1`.
- The result follows the pinned Java `uniformNumbers(int)` formula. The upper bound keeps its repeated-leading-digit intermediate within the source's signed 32-bit `int` range.

The pinned file also includes a two-bound wrapper named `countUniformIntegers`; this benchmark uses its deterministic scalar prefix-count helper directly. The wrapper's equal-bound special case returns 1 for every `a == b`, including nonuniform values, so it is not part of this contract.

## Inspected upstream source

- [Java — `UniformNumbers.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/UniformNumbers.java)

Build and record with the `scalar` ABI family. Implementations are in `u/` in all nine language directories.
