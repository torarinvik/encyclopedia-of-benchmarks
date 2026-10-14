# Base -2 conversion

This benchmark converts any signed 64-bit integer to canonical negabinary, the positional numeral system with radix -2. Every output digit is `0` or `1`; the representation does not need a sign.

## Contract

- Input is one signed 64-bit integer in a one-element array.
- Output is the canonical most-significant-first base -2 representation. Zero is `0`.
- Invalid input returns `-1`; insufficient output capacity returns `-2`.
- Ports use signed division and remainder with a correction that makes each emitted digit 0 or 1, then reverse the remainders.

## Workload and verification

[`workload.json`](workload.json) covers positive and negative examples, alternating bit patterns, and signed 32- and 64-bit boundaries. [`benchmarks/verify_decimal_to_any_base.py`](../../verify_decimal_to_any_base.py) accepts `--algorithm base_neg2_conversion` and checks dense signed values, deterministic 64-bit inputs, capacity failures, and the workload against an independent Euclidean-remainder oracle.

## Reviewed TheAlgorithms source

- [Python `base_neg2_conversion.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/base_neg2_conversion.py) converts by repeated division by -2 and corrects negative remainders to produce binary digits. The benchmark returns the representation as bytes instead of interpreting the digit string as a decimal integer.
