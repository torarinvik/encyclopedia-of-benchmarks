# Any base to decimal

This benchmark folds a most-significant-first digit array into a nonnegative signed 64-bit integer. The first array element is the radix; following elements encode digits with values 0 through 35 (`0`-`9`, `A`-`Z`).

## Contract

- Input length is 2 through 65: one radix and 1 through 64 digits. The radix is 2 through 36.
- Every digit must be nonnegative and less than the radix. Leading zeroes are accepted.
- The result is accumulated with checked signed 64-bit arithmetic; malformed or overflowing input returns `-1`.
- Implementations use portable multiply-and-add arithmetic.

## Workload and verification

[`workload.json`](workload.json) includes common radices, leading zeroes, signed 64-bit maximum, overflow, and invalid inputs. [`verify_any_base_to_decimal.py`](../../verify_any_base_to_decimal.py) checks exhaustive short digit sequences, deterministic random inputs, and boundary cases against Python's arbitrary-precision integer oracle.

## Reviewed TheAlgorithms source

- [Java `AnyBaseToDecimal.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/AnyBaseToDecimal.java) parses digits `0`-`9` and `A`-`Z`; its source uses a narrower integer accumulator, so this contract explicitly detects signed 64-bit overflow.
