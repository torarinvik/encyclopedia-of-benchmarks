# Spy Number

A positive integer is a Spy Number when the sum of its decimal digits equals the product of its decimal digits. The pinned source returns false for zero and negative integers.

## Contract

- Inputs are signed 64-bit integers. Positive values are checked; zero and negative values return `0`.
- Return `1` when the decimal digit sum equals the digit product, and `0` otherwise.
- The implementation scans the digits from right to left in O(d) time and O(1) auxiliary space. Even the product of all 19 possible signed-64-bit decimal digits fits in a signed 64-bit accumulator.

The workload covers nonpositive values, known Spy Numbers, nonexamples, a zero digit, and signed 64-bit endpoints. See [workload.json](workload.json).

The source is the pinned [TheAlgorithms/Python `spy_number.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/spy_number.py), which exposes `is_spy_number(number)`.

Build one port with `python3 benchmarks/build_scalar.py --algorithm spy_number --language LANGUAGE`. The build manifest is written to `build/scalar/s/spy_number/LANGUAGE/build.json`; the workload uses the standard scalar runner interface in [`benchmarks/run_scalar.py`](../../run_scalar.py).
