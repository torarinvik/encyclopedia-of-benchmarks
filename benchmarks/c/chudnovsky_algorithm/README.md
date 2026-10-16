# Chudnovsky algorithm

The pinned Python `pi(precision)` function evaluates the Chudnovsky formula with Decimal precision and formats the result by removing the final character from the Decimal string. This benchmark preserves that behavior for precision values 1 through 12. In this bounded domain, the pinned loop executes only its initial series term; higher precision is excluded because reproducing Decimal's precision and rounding across all nine languages needs a separate arbitrary-precision contract.

The input is a one-element signed 64-bit array containing precision. The output is the exact ASCII string returned by the source, as bytes. Precision 1 therefore returns an empty string, and precision 2 returns `3.`. Invalid inputs return `-1`; after validation, insufficient capacity returns `-2` without writing output.

The ports evaluate `426880 * sqrt(10005) / 13591409` using a short binary64 Newton square-root iteration. The output is at most ten fractional digits, which is sufficient for this bounded source contract. The pinned source is [TheAlgorithms/Python `chudnovsky_algorithm.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/chudnovsky_algorithm.py).
