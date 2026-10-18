# Local weighted learning

This benchmark isolates the deterministic regression core from the pinned
Python implementation. For each training row, it uses that row as a query,
forms Gaussian weights, calculates the local weighted least-squares
coefficients, and predicts at the query row. Dataset loading and plotting are
excluded.

## Contract

The `float64_slice_io` input is
`[n, d, tau, X row-major (n*d values), y (n values)]`. `n` and `d` are exact
integer-valued binary64 inputs. `n` is 2..16, `d` is 1..4, and `d <= n`. The
packed input has exactly `3 + n*d + n` values (at most 83). `X` is the exact
design matrix supplied by the caller; callers include an intercept column if
they want one.

`tau` is in [2, 8], `X` entries are in [-4, 4], and `y` entries are in [-8, 8].
Every `tau`, `X`, and `y` value must be a multiple of 1/16. The design matrix
must have full column rank. All Gaussian weights remain positive in binary64
within these bounds.

For each query row `i`, compute each training-row weight as
`w_j = exp(-||X[i] - X[j]||² / (2*tau²))`, in ascending training-row order.
For each row `j`, accumulate squared distance from `+0.0` in ascending feature
order with `delta = X[i,k] - X[j,k]`, `distance += delta * delta`. Then compute
`tau2 = tau * tau`, `denominator = (-2.0) * tau2`, `exponent = distance /
denominator`, and `weight = exp(exponent)`, rounding each operation to
binary64 without fused multiply-add or reassociation.

Initialize the normal matrix `A` and right side `b` to `+0.0`. In ascending
training-row order, compute `weighted_x[j,q] = weight[j] * X[j,q]` and
`weighted_y[j] = weight[j] * y[j]`; then accumulate `A[p,q] += X[j,p] *
weighted_x[j,q]` and `b[p] += X[j,p] * weighted_y[j]`, with feature indices in
ascending order and one binary64 multiply and addition per update.

The source expresses the coefficients as `A⁻¹b`. Ports solve the equivalent
system `A beta = b` using partial-pivot Gaussian elimination, with this fixed
order: scan pivot candidates from the current row down and keep the first row
on ties; swap full rows and right-side values; eliminate rows downward and
columns to the right in ascending order; back-substitute rows downward and sum
remaining columns in ascending order. Reject a pivot whose magnitude is at
most `2⁻¹⁸` times the maximum absolute diagonal entry of the initial `A`.
Reject rank failures and any nonfinite intermediate or prediction. The
prediction dot product multiplies and adds from feature 0 upward. Outputs are
compared with absolute and relative tolerances of `1e-8` to allow for
NumPy-versus-port binary64 differences.

Output contains `n` float64 predictions in input row order and returns the
element count. Invalid framing, domains, rank/pivot checks, or nonfinite
arithmetic return `-1` before output checks. A null output or capacity below
`n` elements returns `-2`. Errors leave output untouched. The independent
oracle is
[`benchmarks/local_weighted_learning_oracle.py`](../../local_weighted_learning_oracle.py).

## Pinned source

[TheAlgorithms/Python `local_weighted_learning.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/local_weighted_learning/local_weighted_learning.py)
contains `weight_matrix`, `local_weight`, and `local_weight_regression`, along
with separate data-loading and plotting helpers.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/l/local_weighted_learning.c`](../../../c/l/local_weighted_learning.c) |
| C3 | [`c3/l/local_weighted_learning.c3`](../../../c3/l/local_weighted_learning.c3) |
| C++ | [`cpp/l/local_weighted_learning.cpp`](../../../cpp/l/local_weighted_learning.cpp) |
| Elisa | [`elisa/l/local_weighted_learning.elisa`](../../../elisa/l/local_weighted_learning.elisa) |
| Nim | [`nim/l/local_weighted_learning.nim`](../../../nim/l/local_weighted_learning.nim) |
| Odin | [`odin/l/local_weighted_learning.odin`](../../../odin/l/local_weighted_learning.odin) |
| Rust | [`rust/l/local_weighted_learning.rs`](../../../rust/l/local_weighted_learning.rs) |
| V | [`v/l/local_weighted_learning.v`](../../../v/l/local_weighted_learning.v) |
| Zig | [`zig/l/local_weighted_learning.zig`](../../../zig/l/local_weighted_learning.zig) |
