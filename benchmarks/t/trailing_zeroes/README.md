# Trailing Zeroes

Count the decimal zero digits at the end of a nonnegative integer. For example, `102983100000` ends with five zeroes.

## Contract

- Inputs from `0` through `2^63 - 1` are valid. Zero returns `1`; negative inputs return `-1`.
- For positive inputs, divide by ten while the final decimal digit is zero. Time is O(k), where k is the number of trailing zero digits, and auxiliary space is O(1).
- This counts zero digits in the input integer itself. It is separate from `factorial_trailing_zeroes`, which counts factors of five in a factorial.

## Reviewed source

The pinned [Python `trailing_zeroes.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/trailing_zeroes.py) uses repeated division by ten. It returns `1` for zero, `0` for positive integers without a zero suffix, and `-1` for negative values. The nine local ports use the same behavior under the shared signed 64-bit scalar ABI.

See [workload.json](workload.json) and the [scalar verifier](../../verify_scalar.py).
