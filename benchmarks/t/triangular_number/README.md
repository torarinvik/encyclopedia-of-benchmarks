# Triangular Number

Compute the triangular number at a zero-based position: `T(n) = n(n + 1) / 2`. The upstream Python function accepts nonnegative positions and uses arbitrary-precision integers.

## Contract

- Inputs from 0 through 4,294,967,295 are valid. The largest value is the greatest position whose triangular number fits in a signed 64-bit result.
- Negative inputs and positions above that limit return `-1`.
- Implementations divide the even factor before multiplication, so the intermediate product also fits in signed 64-bit arithmetic.
- The function uses the standard unary signed 64-bit scalar ABI and has constant time and space complexity.

The workload includes the initial values, a larger position, the largest supported position, and invalid signed-width and range boundaries. See [workload.json](workload.json).

The source is the pinned [TheAlgorithms/Python `triangular_numbers.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/triangular_numbers.py), whose public function is `triangular_number(position)`.

Build one port with `python3 benchmarks/build_scalar.py --algorithm triangular_number --language LANGUAGE`. The build manifest is written to `build/scalar/t/triangular_number/LANGUAGE/build.json`; the workload uses the standard scalar runner interface in [`benchmarks/run_scalar.py`](../../run_scalar.py).
