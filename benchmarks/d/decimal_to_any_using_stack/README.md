# Decimal to any base using a stack

This benchmark converts a nonnegative signed 64-bit value to a radix from 2 through 16. It pushes each remainder digit into a caller-provided byte buffer and reverses the stack to produce the canonical uppercase representation.

## Contract

- Input is `[value, base]`, with `0 <= value <= INT64_MAX` and `2 <= base <= 16`.
- Digits are `0` through `9`, then uppercase `A` through `F`; zero is `0`.
- Invalid input returns `-1`; insufficient output capacity returns `-2`.
- Ports use portable integer arithmetic and a fixed caller-provided stack buffer.

## Workload and verification

[`workload.json`](workload.json) covers zero, common radices, signed 64-bit boundaries, invalid arguments, and a capacity failure. [`verify_decimal_to_any_base.py`](../../verify_decimal_to_any_base.py) accepts `--algorithm decimal_to_any_using_stack` to check all nine ports against a repeated-division oracle.

## Reviewed TheAlgorithms source

- [Java `DecimalToAnyUsingStack.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/DecimalToAnyUsingStack.java) uses a character stack and supports nonnegative `int` values with radices 2 through 16. The shared contract widens the value domain to signed 64-bit so all target languages share the same input type.
