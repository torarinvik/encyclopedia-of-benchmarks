# Polynomial through points

This benchmark ports `points_to_polynomial` from the pinned Python source at [TheAlgorithms/Python, commit `e1a2a8b016001309a73d5fec4818c35cca139795`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/linear_algebra/src/polynom_for_points.py).

## Contract

Input is a signed-i64 vector `[n, x_0, y_0, ..., x_(n-1), y_(n-1)]`. The bounded domain has 2–8 points, integer x coordinates in `[-4, 4]` with no repeats, and integer y coordinates in `[-25,000, 25,000]`. The vector length must be exactly `1 + 2*n`.

The implementation builds the source's descending-power Vandermonde matrix and performs Gauss–Jordan elimination in the same row and column order. It swaps a pivot row only when the current pivot is zero, choosing the first row with the largest absolute pivot below it. Every source-ordered multiply and subtract rounds separately to binary64: implementations must not contract them into an FMA or reassociate them. As a portable formatting restriction, the bounded contract accepts only finite, exactly integral solved coefficients in `[-1,000,000, 1,000,000]`. Fractional results are invalid (`-1`), even though the Python source can format them. For accepted values, Python `str(float)` is exactly a signed decimal integer followed by `.0`; the sign of zero is preserved as `-0.0` or `0.0`.

The output is the exact ASCII string `f(x)=x^(n-1)*c_(n-1)+...+x^0*c_0`, with every power present, including zero coefficients. The return value is the number of bytes written. Invalid input or a fractional/nonfinite/out-of-bound coefficient returns `-1` before output-buffer checks. A null or short output buffer for a valid result returns `-2` without writing. The maximum encoded result is 124 bytes.

## Workload

[`workload.json`](workload.json) covers the pinned examples, a zero-x pivot, reordered points, the eight-point limit, signed zero formatting, fractional-result rejection, malformed framing and ranges, and null/short/exact output capacities.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/polynom_for_points.c`](../../../c/p/polynom_for_points.c) |
| C3 | [`c3/p/polynom_for_points.c3`](../../../c3/p/polynom_for_points.c3) |
| C++ | [`cpp/p/polynom_for_points.cpp`](../../../cpp/p/polynom_for_points.cpp) |
| Elisa | [`elisa/p/polynom_for_points.elisa`](../../../elisa/p/polynom_for_points.elisa) |
| Nim | [`nim/p/polynom_for_points.nim`](../../../nim/p/polynom_for_points.nim) |
| Odin | [`odin/p/polynom_for_points.odin`](../../../odin/p/polynom_for_points.odin) |
| Rust | [`rust/p/polynom_for_points.rs`](../../../rust/p/polynom_for_points.rs) |
| V | [`v/p/polynom_for_points.v`](../../../v/p/polynom_for_points.v) |
| Zig | [`zig/p/polynom_for_points.zig`](../../../zig/p/polynom_for_points.zig) |

The oracle is [`polynom_for_points_oracle.py`](../../polynom_for_points_oracle.py). The benchmark uses the `i64_array_bytes_output` ABI.

## Pinned source

[TheAlgorithms/Python `polynom_for_points.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/linear_algebra/src/polynom_for_points.py)
