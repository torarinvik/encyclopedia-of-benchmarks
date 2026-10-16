# Binary Cross Entropy

This benchmark ports `binary_cross_entropy` from the pinned TheAlgorithms/Python loss-functions module.

## Contract

- Input is `[n, labels[n], probability_scaled[n]]`, with `1 <= n <= 256` and exact length `1 + 2n`.
- Labels are 0 or 1. Each predicted probability is an integer from 0 through 1,000,000 and represents that value divided by 1,000,000.
- Probabilities are clipped to `[1e-15, 1 - 1e-15]`. The result is the arithmetic mean of `-(y*ln(p) + (1-y)*ln(1-p))`.
- Return one binary64 scalar. Invalid input returns `-1e300`.
- Comparison uses absolute and relative tolerances of `1e-12`.

The independent [`binary_cross_entropy_oracle.py`](../../binary_cross_entropy_oracle.py) evaluates the scalar formula directly.

## Pinned source

[TheAlgorithms/Python `loss_functions.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/loss_functions.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`, method `binary_cross_entropy`.
