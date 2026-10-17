# Sherman–Morrison rank-one inverse update

This benchmark covers the pinned Python `Matrix.sherman_morrison` method. It starts with a supplied inverse matrix `A_inverse` and column vectors `u` and `v`, then applies the rank-one update for `(A + u v^T)^(-1)`. The method assumes `A_inverse` is an inverse and does not verify that assumption.

## Contract

The ABI is `float64_slice_io`. Input is `[n, A_inverse row-major..., u..., v...]`, with `n` from 1 through 4. Every value after `n` must be a finite, exactly integral binary64 value in `[-2, 2]`; `n` itself must be finite and exactly integral. The packed input length is exactly `1 + n*n + 2*n`.

The implementation preserves the source's calculation order. It first forms `v^T * A_inverse`, then multiplies by `u` and adds one. If that denominator is exactly zero, the source returns `None`, represented here as result count 0 and an empty output slice. Otherwise it forms `(A_inverse * u) * (v^T * A_inverse)`, multiplies that matrix by the reciprocal denominator, and subtracts it from `A_inverse`. Return the updated matrix row-major with result count `n*n`. Matrix multiplication accumulates the inner index from zero upward.

Malformed input returns `-1` before output-buffer checks. For valid inputs, a null output pointer returns `-2`; a short output capacity returns `-2` when a matrix must be written. A zero-denominator `None` result requires no output elements, so capacity zero is sufficient. Errors leave the output untouched. Float64 comparisons use absolute and relative tolerances of `1e-12`.

## Pinned source

- `Matrix.sherman_morrison`: [TheAlgorithms/Python at `e1a2a8b016001309a73d5fec4818c35cca139795`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/sherman_morrison.py)

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`sherman_morrison_oracle.py`](../../sherman_morrison_oracle.py)
