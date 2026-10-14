# Negative binary base to integer

This benchmark interprets most-significant-first digits as a base -2 numeral. Unlike ordinary binary, alternating place values are negative and positive, so the representation directly encodes signed values.

## Contract

- Input is an array of 1 through 63 signed 64-bit digits, each `0` or `1`.
- Digits are folded left to right using `value = value * -2 + bit`.
- Malformed digits and invalid lengths return `-1`.
- The 63-digit cap ensures every possible input and intermediate fold fits signed 64-bit.

## Workload and verification

[`workload.json`](workload.json) covers source examples, leading zeroes, maximum-length values, malformed bits, and excessive length. [`benchmarks/verify_negative_binary_base_to_int.py`](../../verify_negative_binary_base_to_int.py) checks all short bit sequences, deterministic longer arrays, and boundary patterns against Python's arbitrary-precision fold.

## Reviewed TheAlgorithms source

- [Python `negative_binary_base_to_int.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/negative_binary_base_to_int.py) treats the input digits as a base -2 numeral and sums their signed positional values. The local contract uses an explicit digit array and checks signed 64-bit overflow.
