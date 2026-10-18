# Simplify fraction

This benchmark preserves the pinned Python `primelib.py` fraction simplifier, including its denominator-sign behavior.

## Contract

The ABI is `i64_array_bytes_output`. Input is exactly `[numerator, denominator]`, with each component in `[-1,000,000, 1,000,000]` and a nonzero denominator. The adapter rejects malformed framing, a zero denominator, or out-of-range components with `-1`.

The source computes `gcd(abs(numerator), abs(denominator))`, then returns `(numerator // gcd, denominator // gcd)`. It does not move a negative sign from the denominator to the numerator. For example, `(10, -20)` becomes `(1, -2)`, and `(0, -15)` becomes `(0, -1)`.

Serialize the result as two signed 64-bit integers in little-endian byte order: reduced numerator, then reduced denominator. The output is always 16 bytes. A null output pointer or capacity below 16 returns `-2` after input validation and without writes.

## Pinned source

The pinned method is [`simplify_fraction`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/primelib.py#L663-L694) in TheAlgorithms/Python commit `e1a2a8b016001309a73d5fec4818c35cca139795`. It calls [`gcd_by_iterative`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/greatest_common_divisor.py), passing absolute values, then divides both original signed inputs by that positive gcd.

See the [workload](workload.json) and [oracle](../../simplify_fraction_oracle.py).
