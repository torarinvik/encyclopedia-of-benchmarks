# Raw R linear regression

This benchmark measures a bounded, deterministic projection of the pinned R
`ols` routine. It fits an intercept and one predictor and returns the ordinary
least-squares coefficients.

## Contract

The `float64_slice_io` input is `[n, x_0, ..., x_(n-1), y_0, ..., y_(n-1)]`.
The sample count is an exact integer from 2 through 32. Each predictor is an
exact integer in `[-4,4]`; each response is an exact integer in `[-16,16]`.
The predictor values must sum to zero and must not all be equal. These
constraints make the intercept and predictor columns full rank. All inputs
must be finite binary64 values.

The pinned R function constructs the design matrix with an intercept and
returns `V diag(1/d) U^T y` from its SVD. On this full-rank bounded domain,
the result is the least-squares intercept and slope. Since the predictor is
centered, the canonical output is `[sum(y)/n, sum(x*y)/sum(x*x)]`, converted
to binary64. Outputs are compared with absolute tolerance `1e-9` and relative
tolerance `1e-12`.

Malformed shapes, a null input pointer at any length, nonfinite or fractional
values, out-of-range values, a noncentered predictor, or a constant predictor
return `-1`. Input validity is checked before output-buffer checks. For valid
input, a null output pointer or capacity below two elements returns `-2`;
successful calls return `2` and write `[intercept, slope]`. Errors leave the
output untouched. The largest valid input contains 65 values; the largest
parseable input contains 66 to represent a trailing-value error. The output
contains two values, each with absolute value at most 16.

## Pinned source

- TheAlgorithms/R [`linearregressionrawr.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/regression_algorithms/linearregressionrawr.r), function `ols`, commit `f65344fabeea0ae33c1ca321af709447c1a8a4c2`

## Workload

The workload is [`workload.json`](workload.json); the independent bounded
oracle is [`benchmarks/linearregressionrawr_oracle.py`](../../linearregressionrawr_oracle.py).
