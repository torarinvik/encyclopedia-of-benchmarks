# Reverse selection sort

At each position, reverse selection sort scans the remaining suffix for its minimum, then reverses the prefix from the current position through that minimum. This places the selected value without a single selection swap; the reversal also changes the order of values within the prefix.

## Contract

- Sort a mutable array of signed 64-bit integers in ascending order.
- Empty and one-element arrays are unchanged.
- Duplicate values and the full signed 64-bit range are supported.
- The sort is not stable.
- It uses constant auxiliary space and quadratic comparison time.

## Workload and verification

The workload uses deterministic modular-affine input at lengths 0, 16, 256, and 1,024. `verify_reverse_selection.py` checks exhaustive short-array order and duplicate patterns, signed 64-bit boundaries, seeded random arrays, and the published workload through the shared sort ABI.

## Reviewed TheAlgorithms source

[Python `reverse_selection.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/reverse_selection.py) selects the minimum in each suffix and reverses the prefix that brings it to its final position. The nine ports retain that reversal strategy with an in-place signed 64-bit contract.
