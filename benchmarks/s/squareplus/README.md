# Squareplus activation

## Contract

Apply the Squareplus activation to one vector element. The `float64_pair` ABI
receives `[x, beta]`; it represents a one-element NumPy vector, so the result is
the single element from the source's elementwise operation. Inputs must be
finite with `x` in `[-10,000, 10,000]` and `beta` in `[0.25, 10,000]`. Invalid
inputs return `-1e300`.

The ports preserve the pinned expression order:

```text
(x + sqrt(x**2 + beta)) / 2
```

The positive beta range keeps the square root defined and the intermediate
values finite. Results are compared with absolute and relative tolerance
`1e-12` for binary64 square-root differences.

## Source and distinction

The contract follows TheAlgorithms Python
[`squareplus.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/activation_functions/squareplus.py)
at commit `e1a2a8b016001309a73d5fec4818c35cca139795`. Its API maps the formula
over a NumPy array and accepts beta as a parameter. This benchmark scalarizes
that vector API to one element. Squareplus is distinct from the other packaged
activations: ReLU and leaky ReLU use piecewise linear functions, sigmoid and
tanh use exponential functions, and binary step returns only zero or one.

[`workload.json`](workload.json) contains the bounded sample cases. The nine
ports use the shared `float64_pair` ABI with parameters `(x, beta)`.
