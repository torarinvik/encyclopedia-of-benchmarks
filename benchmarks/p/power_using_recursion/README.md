# Power Using Recursion

This benchmark follows the pinned recursive power routine: exponent zero returns one, and every positive exponent multiplies the base by the recursive result for the exponent one smaller. It measures linear-depth recursive multiplication, distinct from the divide-and-conquer `power` implementation.

## Contract

- The binary scalar inputs are `(base, exponent)`, both represented as signed 64-bit integers.
- Valid bases are `-10..=10`; valid exponents are `0..=15`.
- A valid call returns the exact integer `base^exponent`. The largest magnitude is `10^15`, exactly representable by the pinned Java `double` return type and within signed 64-bit range.
- Inputs outside either range return `INT64_MIN` (`-9223372036854775808`). This sentinel is separate from valid results, including `(-1)^1 = -1`.
- The pinned Java and Python routines do not handle negative exponents recursively: Java keeps recursing, and the Python function reaches its recursion limit. Negative exponents are outside this contract.

## Workload

[`workload.json`](workload.json) covers zero exponents, zero and unit bases, negative bases, odd and even exponents, maximum magnitudes, and invalid boundaries. It uses the `binary_scalar_call` measurement model.

## Pinned sources

- [Java `PowerUsingRecursion.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PowerUsingRecursion.java) recursively computes `base * power(base, exponent - 1)` and returns `1` at exponent zero.
- [Python `power_using_recursion.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/power_using_recursion.py) uses the same recurrence for nonnegative integer exponents.

