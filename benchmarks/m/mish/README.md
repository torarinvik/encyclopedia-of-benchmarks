# Mish activation

## Contract

Apply the Mish activation to one element of the source vector. The `float64_unary`
ABI supplies `x`; the scalar result represents applying the source NumPy
operation to a one-element vector. Inputs must be finite and in `[-20, 20]`.
Invalid inputs return `-1e300`.

The ports preserve the source's nested evaluation order:

```text
softplus = log(1 + exp(x))
result = x * tanh(softplus)
```

This bounded interval keeps the exponential finite. Results use absolute and
relative tolerance `1e-12` to account for differences among binary64 math
libraries.

## Source and distinction

The contract follows TheAlgorithms Python
[`mish.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/activation_functions/mish.py)
and its sibling
[`softplus.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/activation_functions/softplus.py),
both at commit `e1a2a8b016001309a73d5fec4818c35cca139795`. Mish multiplies its
input by the hyperbolic tangent of Softplus; it therefore differs from the
Softplus output itself and from the standalone tanh activation.

[`workload.json`](workload.json) contains the bounded scalar cases. The nine
ports use the shared `float64_unary` ABI.
