# Soboleva modified hyperbolic tangent

This benchmark applies the pinned vector function elementwise to a bounded
binary64 vector. Its input is `[n, a, b, c, d, x_0, ..., x_(n-1)]`, and its
output contains one binary64 value per sample.

For each `x`, preserve the source's operation order:

```text
numerator   = exp(a*x) - exp(-b*x)
denominator = exp(c*x) + exp(-d*x)
result      = numerator / denominator
```

The vector length is from 1 through 32. Coefficients `a`, `b`, `c`, and `d`
are each in `[-2,2]`; each sample `x` is in `[-20,20]`. Thus every exponent
argument is in `[-40,40]`, preventing exponential overflow and keeping the
denominator positive and nonzero. Invalid shape, non-finite or out-of-range
values return `-1`. A null output pointer or capacity below the vector length
returns `-2` after input validation and writes no output. Output values are
compared with absolute and relative tolerance `1e-12` to accommodate the
source's NumPy exponential implementation across language runtimes.

## Pinned source

The source is TheAlgorithms/Python
[`soboleva_modified_hyperbolic_tangent.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/activation_functions/soboleva_modified_hyperbolic_tangent.py),
commit `e1a2a8b016001309a73d5fec4818c35cca139795`, function
`soboleva_modified_hyperbolic_tangent`.

The bounded workload and independent oracle are [`workload.json`](workload.json)
and
[`benchmarks/soboleva_modified_hyperbolic_tangent_oracle.py`](../../soboleva_modified_hyperbolic_tangent_oracle.py).
