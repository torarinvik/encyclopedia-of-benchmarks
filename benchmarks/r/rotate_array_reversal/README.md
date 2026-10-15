# Rotate Array by Reversal

The pinned Python `rotate_array` source normalizes the signed step count, reverses the entire array, then reverses the prefix and suffix around the rotation boundary. This is a linear-time method distinct from C LeetCode 189’s repeated one-place shifts. The nine ports preserve the three-reversal strategy and return the result in a separate buffer.

## Contract

- The input is `[steps, values...]`; `steps` and every value are signed 32-bit integers. The array has 0 to 1,024 values.
- Positive steps rotate right; negative steps rotate left. The step count is normalized modulo the array length. Empty arrays return empty output.
- Return the rotated values as little-endian signed 32-bit integers and return the element count.
- Return `-1` for malformed lengths or values, and `-2` if the output buffer is too small.
- The input is left unchanged. The three reversals take O(n) time and use O(n) local storage for the copy.

Run `python3 benchmarks/verify_rotate_array_reversal.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` from the repository root to check all nine ports against exhaustive short arrays, seeded random inputs, signed-step boundaries, malformed inputs, and the published workload.

## Inspected upstream source

- [Python — `rotate_array.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/rotate_array.py)
